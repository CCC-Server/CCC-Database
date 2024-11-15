-- 운마물-슈퍼 타이푼
-- Set 1 Continuous Trap that can Special Summon itself as a monster
local s,id=GetID()
function s.initial_effect(c)
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x18),2,99) -- "운마물" 몬스터 2장 이상
	c:EnableReviveLimit()
	
	-- 효과 1: "운마물" 함정 카드를 덱 또는 묘지에서 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK) end)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	
	-- 효과 2: 포그 카운터를 제거하고 필드 카드 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetCountLimit(1,{id,1})
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.effect2_condition)
	e2:SetCost(s.effect2_cost)
	e2:SetTarget(s.effect2_target)
	e2:SetOperation(s.effect2_operation)
	c:RegisterEffect(e2)
end
s.listed_series={0x18}

function s.setfilter(c)
	return c:IsSetCard(0x18) and c:IsTrap() and c:IsSSetable()
end

-- 효과 1 목표: "운마물" 함정 카드를 덱 또는 묘지에서 세트할 수 있도록 설정
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) or Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
end

-- 효과 1 처리: "운마물" 함정 카드를 덱 또는 묘지에서 세트
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end

-- 효과 2 조건: 필드의 포그 카운터가 3의 배수일 때
function s.effect2_condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsCanRemoveCounter(tp,1,0,0x1019,3,REASON_COST)
end

-- 효과 2 비용: 포그 카운터를 제거
function s.effect2_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,1,0,0x1019,3,REASON_COST) end
	Duel.RemoveCounter(tp,1,0,0x1019,3,REASON_COST)
end

-- 효과 2 목표: 제거한 카운터 수에 따라 파괴할 카드 지정
function s.effect2_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDestructable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local ct=Duel.GetCounter(tp,1,0,0x1019)/3
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,ct,0,0)
end

-- 효과 2 처리: 필드의 카드 파괴
function s.effect2_operation(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetCounter(tp,1,0,0x1019)/3
	if ct>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,Card.IsDestructable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end