local s, id = GetID()

function s.initial_effect(c)
	-- ① 효과: 패에서 발동
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Set the Special Summon limit
	c:SetSPSummonOnce(id)

	-- extra summon
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetOperation(s.sumop2)
	c:RegisterEffect(e2)

	-- Grant direct attack ability when used as Fusion Material
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.fusion_material_condition)
	e4:SetOperation(s.fusion_material_operation)
	c:RegisterEffect(e4)
end

-- ① 효과
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeckAsCost, tp, LOCATION_HAND, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local g = Duel.SelectMatchingCard(tp, Card.IsAbleToDeckAsCost, tp, LOCATION_HAND, 0, 1, 1, nil)
	Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_COST)
end

function s.thfilter(c)
	return c:IsSetCard(0x42d) and c:IsType(TYPE_SPELL) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

function s.sumop2(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()

	-- 1. 전투로 파괴되지 않도록 하기
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. 1번 배틀 페이즈 중 2회 공격 가능
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(1)
	c:RegisterEffect(e2)
end

-- Grant "U.K" monsters on your field the ability to attack directly
function s.fusion_material_operation(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(s.uk_filter, tp, LOCATION_MZONE, 0, nil)
	local c = e:GetHandler()
	local tc = g:GetFirst()
	while tc do
		-- Allow direct attack
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DIRECT_ATTACK)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(e1)
		tc = g:GetNext()
	end
end

-- Filter for "U.K" monsters
function s.uk_filter(c)
	return c:IsSetCard(0x42d) and c:IsFaceup()
end

-- Condition for fusion material (added this function)
function s.fusion_material_condition(e, tp, eg, ep, ev, re, r, rp)
	-- Example condition: this can be adjusted based on your needs
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

