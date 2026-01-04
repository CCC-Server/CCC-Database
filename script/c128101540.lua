local s,id=GetID()
function s.initial_effect(c)
	--기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}
	
	--①: 패 특수 소환 및 발동 횟수에 따른 효과
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--②: 반달기온 관련 카드 회수 및 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 글로벌 카운터 (파괴 및 카운터 함정 발동 체크)
	if not s.global_check then
		s.global_check=true
		-- 효과 파괴 체크
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_DESTROYED)
		ge1:SetOperation(s.checkop_dest)
		Duel.RegisterEffect(ge1,0)
		-- 카운터 함정 발동 횟수 체크
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_CHAIN_ACTIVATING)
		ge2:SetOperation(s.checkop_count)
		Duel.RegisterEffect(ge2,0)
	end
end

-- 글로벌 체크: 효과 파괴 여부 저장
function s.checkop_dest(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsReason,1,nil,REASON_EFFECT) then
		Duel.RegisterFlagEffect(0,id+100,RESET_PHASE+PHASE_END,0,1)
		Duel.RegisterFlagEffect(1,id+100,RESET_PHASE+PHASE_END,0,1)
	end
end

-- 글로벌 체크: 카운터 함정 발동 및 횟수 기록
function s.checkop_count(e,tp,eg,ep,ev,re,r,rp)
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsType(TYPE_COUNTER) then
		-- 발동 여부 플래그
		Duel.RegisterFlagEffect(0,id+200,RESET_PHASE+PHASE_END,0,1)
		Duel.RegisterFlagEffect(1,id+200,RESET_PHASE+PHASE_END,0,1)
		-- 발동 횟수 카운팅용 플래그
		Duel.RegisterFlagEffect(0,id+300,RESET_PHASE+PHASE_END,0,1)
		Duel.RegisterFlagEffect(1,id+300,RESET_PHASE+PHASE_END,0,1)
	end
end

-- ① 효과 조건: 이번 턴에 효과 파괴가 있었거나 카운터 함정이 발동되었을 것
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id+100)>0 or Duel.GetFlagEffect(tp,id+200)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
		and not c:IsPublic() end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	-- 특수 소환
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local ct=Duel.GetFlagEffect(tp,id+300) -- 이번 턴 카운터 함정 발동 횟수
		
		-- 1장 이상: 상대 카드 1장 파괴 + 1500 데미지
		if ct>=1 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
			if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
				 Duel.Damage(1-tp,1500,REASON_EFFECT)
			end
		end
		
		-- 2장 이상: 묘지/제외 카운터 함정 세트
		if ct>=2 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,TYPE_COUNTER)
			if #g>0 then
				Duel.SSet(tp,g:GetFirst())
			end
		end
		
		-- 3장 이상: 상대 묘지 전부 제외
		if ct>=3 then
			Duel.BreakEffect()
			local rg=Duel.GetFieldGroup(tp,0,LOCATION_GRAVE)
			if #rg>0 then
				Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end

-- ② 효과 필터: "명왕룡 반달기온"의 카드명이 쓰여진 카드 (필드/묘지)
function s.thfilter(c)
	return (c:IsFaceup() or not c:IsLocation(LOCATION_MZONE)) 
		and (c:IsCode(24857466) or c:ListsCode(24857466)) 
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
		-- 그 후, 상대 필드의 카드 1장 파괴 (할 수 있다)
		local dg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=dg:Select(tp,1,1,nil)
			Duel.HintSelection(sg)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end