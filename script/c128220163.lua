--메가록 앤젤
local s,id=GetID()
function c128220163.initial_effect(c)
-- ①: 패의 암석족 제외하고 특수 소환 + 표시 형식 변경
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.rock_lock_cost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 소환 시 표시 형식 변경 및 무효화
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_POSITION + CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1, id + 100)
	e2:SetCost(s.rock_lock_cost)
	e2:SetTarget(s.postg)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- ③: 리버스 시 싱크로 소환 실행
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_FLIP)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetTarget(s.syntg)
	e4:SetOperation(s.synop)
	c:RegisterEffect(e4)
end

-- 암석족 특소 제약 (OATH 코스트)
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

-- ① 프리 체인 특소 효과
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetCurrentPhase() == PHASE_MAIN1 or Duel.GetCurrentPhase() == PHASE_MAIN2
end
function s.costfilter(c)
	return c:IsRace(RACE_ROCK) and c:IsAbleToRemoveAsCost()
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	local c = e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsCanTurnFaceDown() end
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
		and Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND, 0, 1, c)
		and Duel.IsExistingTarget(Card.IsCanTurnFaceDown, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND, 0, 1, 1, c)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEDOWN)
	local tg = Duel.SelectTarget(tp, Card.IsCanTurnFaceDown, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_POSITION, tg, 1, 0, 0)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		if tc:IsRelateToEffect(e) and tc:IsFaceup() then
			Duel.ChangePosition(tc, POS_FACEDOWN_DEFENSE)
		end
	end
end

-- ② 표시 형식 변경 및 무효화
function s.postg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFacedown() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsFacedown, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_POSCHANGE)
	local g = Duel.SelectTarget(tp, Card.IsFacedown, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_POSITION, g, 1, 0, 0)
end
function s.posop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFacedown() then
		local pos = Duel.SelectPosition(tp, tc, POS_FACEUP_ATTACK + POS_FACEUP_DEFENSE)
		if Duel.ChangePosition(tc, pos) > 0 and tc:IsFaceup() then
			local e1 = Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2 = e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
		end
	end
end

-- ③ 싱크로 소환 실행
function s.syntg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsSynchroSummonable, tp, LOCATION_EXTRA, 0, 1, nil, e:GetHandler()) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end
function s.synop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsControler(1 - tp) or not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local g = Duel.GetMatchingGroup(Card.IsSynchroSummonable, tp, LOCATION_EXTRA, 0, nil, c)
	if #g > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local sg = g:Select(tp, 1, 1, nil)
		Duel.SynchroSummon(tp, sg:GetFirst(), c)
	end
end