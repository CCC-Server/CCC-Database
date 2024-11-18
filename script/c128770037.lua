local s, id = GetID()
function s.initial_effect(c)
	-- Activate: Search 2 "M.A" monsters with a restriction
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Cost: Discard 1 card from the hand
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
	Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
end

-- Target: Search for 2 "M.A" monsters from the Deck
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		local g = Duel.GetMatchingGroup(s.filter, tp, LOCATION_DECK, 0, nil)
		return #g >= 2
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK)
end

-- Filter: Only "M.A" monsters with the correct Set Code
function s.filter(c)
	return c:IsSetCard(0x30d) and c:IsMonster() and c:IsAbleToHand()
end

-- Activate: Add 2 "M.A" monsters to the hand with level restriction
function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(s.filter, tp, LOCATION_DECK, 0, nil)
	if #g >= 2 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local sg = Group.CreateGroup()
		-- Select the first "M.A" monster
		local tc1 = g:Select(tp, 1, 1, nil):GetFirst()
		sg:AddCard(tc1)
		g:Remove(Card.IsLevel, nil, tc1:GetLevel()) -- Remove monsters with the same level as the first one
		-- Select the second "M.A" monster
		if #g > 0 then
			local tc2 = g:Select(tp, 1, 1, nil):GetFirst()
			sg:AddCard(tc2)
		end
		Duel.SendtoHand(sg, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, sg)
	end
end
