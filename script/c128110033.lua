-- 식수파괴수 바이란테
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터 ID
function s.initial_effect(c)
	-- 파괴수 공통 제약 (③): 필드에 "파괴수" 몬스터는 1장만 존재 가능
	c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsSetCard,0xd3),LOCATION_MZONE)
	
	-- 파괴수 공통 특수 소환 룰 (①, ②)
	-- ①: 상대 필드 몬스터 릴리스 후 상대 필드 특수 소환
	-- ②: 상대 필드에 파괴수 존재 시 패에서 특수 소환
	local e1,e2=aux.AddKaijuProcedure(c)
	
	-- ④: 마법 / 함정 발동 무효
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end
s.listed_series={0xd3} -- 파괴수
s.counter_list={COUNTER_KAIJU} -- 파괴수 카운터 사용

-- ④ 효과: 조건 (상대가 마법/함정 카드 발동)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and Duel.IsChainNegatable(ev)
end

-- ④ 효과: 코스트 (카운터 2개 제거)
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,1,1,COUNTER_KAIJU,2,REASON_COST) end
	Duel.RemoveCounter(tp,1,1,COUNTER_KAIJU,2,REASON_COST)
end

-- ④ 효과: 타겟 (무효 및 파괴)
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- ④ 효과: 처리
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end