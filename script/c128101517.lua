--프레데터 플랜츠 비너스 트랩
--Predaplant Venus Trap
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 절차: 어둠 속성 몬스터 2장
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),2,2)
	c:EnableReviveLimit()
	
	--①: 자신 / 상대 턴에 몬스터 1장에 포식 카운터 배치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER|TIMING_END_PHASE)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	
	--②: 카드의 효과가 발동했을 경우에 어둠 속성 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
        e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})   
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

s.counter_list={COUNTER_PREDATOR}

--①번 효과: 포식 카운터 배치 및 레벨 변경
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		tc:AddCounter(COUNTER_PREDATOR,1)
		if tc:GetCounter(COUNTER_PREDATOR)>0 and tc:GetLevel()>1 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetCondition(s.lvcon)
			e1:SetValue(1)
			tc:RegisterEffect(e1)
		end
	end
end
function s.lvcon(e)
	return e:GetHandler():GetCounter(COUNTER_PREDATOR)>0
end

--②번 효과: 융합 소환 처리
function s.fcheck(c,mg,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsAttribute(ATTRIBUTE_DARK)
		and Duel.GetLocationCountFromEx(tp,tp,mg,c)>0
		and c:CheckFusionMaterial(mg,nil,tp)
end
function s.mfilter(c,tp)
	-- 내 패/필드 몬스터 또는 포식 카운터가 놓인 상대 필드 몬스터
	return c:IsCanBeFusionMaterial() and (c:IsControler(tp) or (c:IsControler(1-tp) and c:GetCounter(COUNTER_PREDATOR)>0))
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_HAND|LOCATION_MZONE,LOCATION_MZONE,nil,tp)
		return Duel.IsExistingMatchingCard(s.fcheck,tp,LOCATION_EXTRA,0,1,nil,mg,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 소재 그룹 형성 (상대 필드 카운터 몬스터 포함)
	local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_HAND|LOCATION_MZONE,LOCATION_MZONE,nil,tp)
	
	-- 2. 소환 가능한 융합 몬스터 필터링
	local sg=Duel.GetMatchingGroup(s.fcheck,tp,LOCATION_EXTRA,0,nil,mg,e,tp)
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=sg:Select(tp,1,1,nil):GetFirst()
		
		-- 3. 융합 소재 선택 (상대 몬스터는 최대 1장까지만 선택되도록 처리)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
		local op_mat=mat:Filter(Card.IsControler,nil,1-tp)
		
		-- 상대 소재가 1장을 초과할 경우 다시 선택하도록 안전장치 (통상적으로는 1장만 카운터가 있다면 1장만 선택됨)
		if #op_mat>1 then
			return -- 불가능한 선택 시 처리 중단
		end
		
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
			tc:CompleteProcedure()
		end
	end
end