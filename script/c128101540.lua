local s,id=GetID()
function s.initial_effect(c)
	-- 기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}

	-- ①: 특수 소환 및 발동 횟수에 따른 효과
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMING_END_PHASE+TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 관련 카드 회수 및 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMING_END_PHASE+TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 글로벌 체크: 카운터 함정 발동 횟수 및 효과 파괴 기록
	if not s.global_check then
		s.global_check=true
		-- 카운터 함정 발동 체크 (횟수 누적을 위해 0번 플레이어에게 id 플래그 등록)
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
		-- 효과 파괴 발생 체크
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_DESTROYED)
		ge2:SetOperation(s.descheckop)
		Duel.RegisterEffect(ge2,0)
	end
end

-- 카운터 함정 발동 시마다 플래그를 하나씩 쌓음
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_TRAP) and re:IsActiveType(TYPE_COUNTER) then
		-- 0번 플레이어(시스템)에게 플래그를 쌓아 턴 전체 횟수 기록
		Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1)
	end
end

-- 효과 파괴 발생 시 플래그 등록
function s.descheckop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsReason,1,nil,REASON_EFFECT) then
		Duel.RegisterFlagEffect(0,id+100,RESET_PHASE+PHASE_END,0,1)
	end
end

-- ① 효과 조건: 이번 턴에 카함 발동(id 플래그) 혹은 효과 파괴(id+100 플래그) 발생 시
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(0,id)>0 or Duel.GetFlagEffect(0,id+100)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

-- 카운터 함정 세트 필터
function s.ctfilter(c)
	return c:IsType(TYPE_TRAP) and c:IsType(TYPE_COUNTER) and c:IsSSetable()
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 패의 이 카드를 상대에게 보여주고 특수 소환
	Duel.ConfirmCards(1-tp,c)
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 실제 이번 턴 카운터 함정 발동 횟수 가져오기
		local ct=Duel.GetFlagEffect(0,id)
		
		-- ● 1장 이상: 상대 필드 카드 1장 파괴 + 1500 데미지
		if ct>=1 then
			local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
			if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
				local sg=g:Select(tp,1,1,nil)
				Duel.HintSelection(sg)
				if Duel.Destroy(sg,REASON_EFFECT)>0 then
					Duel.Damage(1-tp,1500,REASON_EFFECT)
				end
			end
		end
		
		-- ● 2장 이상: 자신의 묘지/제외 상태 카운터 함정 1장 세트
		if ct>=2 then
			local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.ctfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
			if #g>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
				local sg=g:Select(tp,1,1,nil)
				Duel.SSet(tp,sg)
			end
		end
		
		-- ● 3장 이상: 상대 묘지 전부 제외
		if ct>=3 then
			local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
			if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
				Duel.BreakEffect()
				Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end

-- ② 효과 관련 필터 (명왕룡 반달기온 기재 카드)
function s.thfilter(c)
	return (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
		and (c:IsCode(24857466) or c:ListsCode(24857466))
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_ONFIELD+LOCATION_GRAVE) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil) end
	 Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
		-- 그 후 상대 필드 카드 1장 파괴 (비대상, 임의)
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=g:Select(tp,1,1,nil)
			Duel.HintSelection(sg)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end