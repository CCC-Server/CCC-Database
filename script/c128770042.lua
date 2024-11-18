local s, id = GetID()
function s.initial_effect(c)
	-- Activate: Set as a Continuous Trap
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effect 1: Special Summon an "M.A" monster from banished zone
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effect 2: Destroy a card on the opponent's field
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1, id + 1)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- Effect 1: Check if opponent Special Summons a monster
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(Card.IsControler, 1, nil, 1 - tp)
end

-- Effect 1: Target an "M.A" monster in the banished zone
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingTarget(s.spfilter, tp, LOCATION_REMOVED, 0, 1, nil, e, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_REMOVED, 0, 1, 1, nil, e, tp)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

-- Filter for "M.A" monsters in the banished zone
function s.spfilter(c, e, tp)
	return c:IsSetCard(0x30d) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

-- Effect 1: Special Summon the targeted "M.A" monster
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		-- Return to Deck/Extra Deck if it leaves the field
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT + RESETS_REDIRECT)
		if tc:IsLocation(LOCATION_EXTRA) then
			e1:SetValue(LOCATION_EXTRA)
		else
			e1:SetValue(LOCATION_DECKSHUFFLE)
		end
		tc:RegisterEffect(e1)
	end
end

-- Effect 2: Check if an "M.A" card is banished
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.desfilter, 1, nil, tp)
end

-- Filter for "M.A" cards that were banished
function s.desfilter(c, tp)
	return c:IsSetCard(0x30d) and c:IsControler(tp)
end

-- Effect 2: Target an opponent's card for destruction
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1 - tp) end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsDestructable, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

-- Effect 2: Destroy the targeted card
function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
