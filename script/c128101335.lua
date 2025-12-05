--하이메타파이즈 레인보우 드래곤
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x105),1,1,
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x105),1,99)

	------------------------------------------------------------
	-- ①: 상대 카드 효과 발동 무효 + 파괴
	------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	------------------------------------------------------------
	-- ②: 자신을 Extra로 되돌리고 / 묘지·제외의 "메타파이즈" 2장 특소
	------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) end)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

------------------------------------------------------------
-- ① 조건 : 상대 카드 효과 발동 시
------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev)
end

------------------------------------------------------------
-- ① 비용 : 제외 상태의 메타파이즈 카드 1장 덱으로 되돌리기
------------------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x105) and c:IsAbleToDeckAsCost()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_REMOVED,0,1,nil)
	end
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_REMOVED,0,1,1,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

------------------------------------------------------------
-- ① 타겟 설정
------------------------------------------------------------
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

------------------------------------------------------------
-- ① 실행 : 효과 무효 + 파괴
------------------------------------------------------------
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

------------------------------------------------------------
-- ② 타겟 : 묘지/제외 상태의 메타파이즈 2장 특소
------------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x105) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsAbleToExtra() 
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

------------------------------------------------------------
-- ② 실행 : 자신을 Extra로 → 메타파이즈 2장 특수 소환
------------------------------------------------------------
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)>0) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end

	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,2,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
