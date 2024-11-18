local s, id = GetID()
function s.initial_effect(c)
	-- Activate: Negate and banish
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_NEGATE + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Condition: Check if there are at least 2 "M.A" monsters on the field
function s.condition(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.mafilter, tp, LOCATION_MZONE, 0, 2, nil)
		and re:IsActiveType(TYPE_MONSTER + TYPE_SPELL + TYPE_TRAP)
		and Duel.IsChainNegatable(ev)
end

-- Filter for "M.A" monsters
function s.mafilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30d)
end

-- Target: Negate and banish the activated effect
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, eg, 1, 0, 0)
end

-- Operation: Negate, banish, and prevent activation of cards with the same name
function s.activate(e, tp, eg, ep, ev, re, r, rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg, POS_FACEUP, REASON_EFFECT)
		-- Prevent activation of cards with the same original name until the end of the next turn
		local c = e:GetHandler()
		local tc = re:GetHandler()
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetTargetRange(0, 1)
		e1:SetValue(function(e, re, tp)
			return re:GetHandler():IsOriginalCodeRule(tc:GetOriginalCodeRule())
		end)
		e1:SetReset(RESET_PHASE + PHASE_END + RESET_OPPO_TURN)
		Duel.RegisterEffect(e1, tp)
	end
end
