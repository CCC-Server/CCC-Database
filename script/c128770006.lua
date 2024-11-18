local s, id = GetID()
function s.initial_effect(c)
	-- Enable counter
	c:EnableCounterPermit(0x250a)
	
	-- 효과 ①: "M.A" 몬스터의 공격력 상승 및 사도 카운터 올리기
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.counter_condition)
	e1:SetOperation(s.counter_operation)
	c:RegisterEffect(e1)
	
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE, 0)
	e2:SetTarget(s.atk_target)
	e2:SetValue(400)
	c:RegisterEffect(e2)

	-- 효과 ②: 패에서 "M.A" 몬스터 특수 소환
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.spsummon_target)
	e3:SetOperation(s.spsummon_operation)
	c:RegisterEffect(e3)

	-- 효과 ③: 사도 카운터가 12개일 때 "M.A-백야" 특수 소환
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE + PHASE_STANDBY)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.special_condition)
	e4:SetCost(s.special_cost)
	e4:SetTarget(s.special_target)
	e4:SetOperation(s.special_operation)
	c:RegisterEffect(e4)
end

-- 사도 카운터 코드 및 "M.A" 몬스터 코드 정의
s.counter_code = 0x250a
s.ma_set_code = 0x30d
s.white_night_code = 128770019

-- 효과 ①: "M.A" 몬스터의 공격력 상승 및 사도 카운터 올리기
function s.counter_condition(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(Card.IsSetCard, 1, nil, s.ma_set_code)
end

function s.counter_operation(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsFaceup() and c:GetCounter(s.counter_code) < 12 then
		c:AddCounter(s.counter_code, 1)
	end
end

function s.atk_target(e, c)
	return c:IsSetCard(s.ma_set_code)
end

-- 효과 ②: 패에서 "M.A" 몬스터 특수 소환
function s.spsummon_target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spsummon_filter, tp, LOCATION_HAND, 0, 1, nil, e, tp) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
end

function s.spsummon_filter(c, e, tp)
	return c:IsSetCard(s.ma_set_code) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.spsummon_operation(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spsummon_filter, tp, LOCATION_HAND, 0, 1, 1, nil, e, tp)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- 효과 ③: 사도 카운터가 12개일 때 "M.A-백야" 특수 소환
function s.special_condition(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:GetCounter(s.counter_code) >= 12
end

function s.special_cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c, REASON_COST)
end

function s.special_target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCountFromEx(tp) > 0
		and Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsCode, s.white_night_code), tp, LOCATION_EXTRA, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.special_operation(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local white_night = Duel.SelectMatchingCard(tp, aux.FilterBoolFunction(Card.IsCode, s.white_night_code), tp, LOCATION_EXTRA, 0, 1, 1, nil):GetFirst()
	if white_night then
		Duel.SpecialSummon(white_night, SUMMON_TYPE_SPECIAL, tp, tp, false, false, POS_FACEUP)
		white_night:CompleteProcedure()
	end
end
