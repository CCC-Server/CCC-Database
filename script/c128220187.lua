--비르투스 그랜드피아노
local s,id=GetID()
function c128220187.initial_effect(c)
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),5,2)
	c:EnableReviveLimit()

	-- ①: 자신 / 상대 턴에, 엑시즈 소재를 1개 제거하고 발동 (페이즈별 유발 즉시 효과)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY + CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(TIMING_DRAW_PHASE + TIMING_STANDBY_PHASE + TIMING_MAIN_END + TIMING_BATTLE_PHASE + TIMING_END_PHASE)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- ②: 서로의 엔드 페이즈에 발동 (1턴에 1번)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE + PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)
end

-- "비르투스" 카드군 필터
function s.virtus_filter(c)
	return c:IsSetCard(0xc29) -- [중요] 여기에 '비르투스'의 카드군 고유 번호(HEX)를 입력하세요.
end

---------------------------------------------------------------------------------
-- ①번 효과 처리
---------------------------------------------------------------------------------
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local phase = Duel.GetCurrentPhase()
	
	if chk==0 then
		if phase == PHASE_DRAW or phase == PHASE_STANDBY then
			return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
				and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.virtus_filter), tp, LOCATION_GRAVE, 0, 1, nil, e, 0, tp, false, false)
		
		elseif phase == PHASE_MAIN1 or phase == PHASE_MAIN2 then
			return Duel.IsExistingMatchingCard(nil, tp, 0, LOCATION_ONFIELD, 1, nil)
		
		elseif phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE then
			return true
		
		elseif phase == PHASE_END then
			return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
				and Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND, 0, 1, nil, e, 0, tp, false, false)
		end
		return false
	end

	if phase == PHASE_DRAW or phase == PHASE_STANDBY then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
	elseif phase == PHASE_MAIN1 or phase == PHASE_MAIN2 then
		e:SetCategory(CATEGORY_DESTROY)
		local g = Duel.GetMatchingGroup(nil, tp, 0, LOCATION_ONFIELD, nil)
		Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
	elseif phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE then
		e:SetCategory(CATEGORY_ATKCHANGE)
	elseif phase == PHASE_END then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
	end
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local phase = Duel.GetCurrentPhase()
	local c = e:GetHandler()

	-- ● 드로우 페이즈 / 스탠바이 페이즈
	if phase == PHASE_DRAW or phase == PHASE_STANDBY then
		if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.virtus_filter), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, 0, tp, false, false)
		if #g > 0 then
			Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
		end

	-- ● 메인 페이즈
	elseif phase == PHASE_MAIN1 or phase == PHASE_MAIN2 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
		local g = Duel.SelectMatchingCard(tp, nil, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
		if #g > 0 then
			Duel.HintSelection(g)
			Duel.Destroy(g, REASON_EFFECT)
		end

	-- ● 배틀 페이즈
	elseif phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE then
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1 = Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK) -- 공격력 수치 가산 효과
			e1:SetValue(1500)                 -- 1500 상승
			e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			c:RegisterEffect(e1)
		end

	-- ● 엔드 페이즈
	elseif phase == PHASE_END then
		if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local g = Duel.SelectMatchingCard(tp, Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND, 0, 1, 1, nil, e, 0, tp, false, false)
		if #g > 0 then
			Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
		end
	end
end

---------------------------------------------------------------------------------
-- ②번 효과 처리
---------------------------------------------------------------------------------
function s.xyztg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then 
		return e:GetHandler():IsType(TYPE_XYZ) 
			and Duel.IsExistingMatchingCard(s.virtus_filter, tp, LOCATION_GRAVE, 0, 1, nil) 
	end
end

function s.xyzop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_XMATERIAL)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.virtus_filter), tp, LOCATION_GRAVE, 0, 1, 1, nil)
	if #g > 0 then
		Duel.Overlay(c, g)
	end
end