local s,id=GetID()
function s.initial_effect(c)
	-- 기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}

	-- ①: 특수 소환 및 덱/묘지 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 세트 카드 파괴 내성
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,0)
	e2:SetTarget(s.indtg)
	e2:SetValue(aux.indoval)
	c:RegisterEffect(e2)

	-- ③: 제외된 카운터 함정 세트 및 추가 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)

	-- 글로벌 체크: 턴 중 발동 여부 확인
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

-- 안전하게 카드 조건을 확인하는 보조 함수
function s.is_vandal_related(c)
	if not c then return false end
	return c:IsCode(24857466) or (c.ListsCode and c:ListsCode(24857466))
end

function s.is_counter_trap(c)
	if not c then return false end
	return c:IsType(TYPE_TRAP) and c:IsType(TYPE_COUNTER)
end

-- 조건 체크용 글로벌 함수
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if not re then return end
	local rc=re:GetHandler()
	if not rc then return end

	-- ①번 효과 조건 기록
	if rc:GetCode()~=id then
		if s.is_vandal_related(rc) or s.is_counter_trap(rc) then
			Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1)
			Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1)
		end
	end
	
	-- ③번 효과 추가 조건: 자신이 카운터 함정을 발동했는지 체크
	if s.is_counter_trap(rc) then
		Duel.RegisterFlagEffect(rp,id+100,RESET_PHASE+PHASE_END,0,1)
	end
end

-- ① 효과
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.rmfilter(c)
	return s.is_counter_trap(c) and s.is_vandal_related(c) and c:IsAbleToRemove()
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local sg=g:Select(tp,1,1,nil)
			Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
		end
	end
end

-- ② 효과
function s.indtg(e,c)
	return c:IsFacedown()
end

-- ③ 효과
function s.setfilter(c)
	return s.is_counter_trap(c) and c:IsSSetable() and c:IsFaceup()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.setfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.setfilter,tp,LOCATION_REMOVED,0,1,nil) end
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	local ct=math.min(ft,3)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_REMOVED,0,1,ct,nil)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		if Duel.SSet(tp,g)>0 then
			-- 카운터 함정을 발동했던 턴이라면 추가 파괴
			if Duel.GetFlagEffect(tp,id+100)>0 then
				local dg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
				if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
					Duel.BreakEffect()
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
					local des=dg:Select(tp,1,1,nil)
					Duel.HintSelection(des)
					Duel.Destroy(des,REASON_EFFECT)
				end
			end
		end
	end
end