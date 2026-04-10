--메가록 레비아탄
local s,id=GetID()
function c128220166.initial_effect(c)
local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- ①: 패/묘지의 암석족을 임의의 수만큼 제외하고 특수 소환 (프리 체인)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
	e1:SetCountLimit(1, id) -- 카드명 제약 (발동 턴 암석족 락 포함)
	e1:SetCost(s.rock_lock_cost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 원래 공/수 결정 (제외 상태 암석족 * 700)
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_BASE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.adval)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e3)

	-- ③: 소환 시 "메가록 드래곤" 서치/회수
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1, id + 100)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

-- 덱 특소 불가
function s.splimit(e, se, sp, st)
	return not (st & SUMMON_TYPE_SPECIAL == SUMMON_TYPE_SPECIAL and se:GetHandler():IsLocation(LOCATION_DECK))
end

-- 암석족 특소 제약 (OATH)
function s.rock_lock_cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetCustomActivityCount(id, tp, ACTIVITY_SPSUMMON) == 0 end
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1, 0)
	e1:SetTarget(s.splimit_rock)
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)
end
function s.splimit_rock(e, c)
	return not c:IsRace(RACE_ROCK)
end

-- ① 특수 소환 효과
function s.rmfilter(c)
	return c:IsRace(RACE_ROCK) and c:IsAbleToRemove()
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
		and Duel.IsExistingMatchingCard(s.rmfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, c) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_HAND + LOCATION_GRAVE)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g = Duel.GetMatchingGroup(s.rmfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, c)
	if #g > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
		local sg = g:Select(tp, 1, #g, nil) -- 임의의 수만큼 제외
		if Duel.Remove(sg, POS_FACEUP, REASON_EFFECT) > 0 then
			Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
		end
	end
end

-- ② 공/수 계산
function s.adval(e, c)
	local tp = e:GetHandlerPlayer()
	local count = Duel.GetMatchingGroupCount(Card.IsRace, tp, LOCATION_REMOVED, 0, nil, RACE_ROCK)
	return count * 700
end

-- ③ 메가록 드래곤 서치 (ID: 6022371 - 메가록 드래곤의 실제 카드 번호)
function s.thfilter(c)
	return c:IsCode(71544954) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end
