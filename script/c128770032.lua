local s, id = GetID()
function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c, nil, 7, 2)
	c:EnableReviveLimit()

	-- Effect 1: Banish a Spell/Trap and negate effects
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_REMOVE + CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.rmcost)
	e1:SetTarget(s.rmtarget)
	e1:SetOperation(s.rmoperation)
	c:RegisterEffect(e1)

	-- Effect 2: Transfer self and Xyz materials
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1, id + 1)
	e2:SetTarget(s.transtarget)
	e2:SetOperation(s.transoperation)
	c:RegisterEffect(e2)
end

-- Effect 1: Cost to remove 1 Xyz Material
function s.rmcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

-- Effect 1: Target to banish a Spell/Trap and negate effects
function s.rmtarget(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsType(TYPE_SPELL + TYPE_TRAP) and chkc:IsControler(1 - tp) end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsType, tp, 0, LOCATION_ONFIELD, 1, nil, TYPE_SPELL + TYPE_TRAP) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectTarget(tp, Card.IsType, tp, 0, LOCATION_ONFIELD, 1, 1, nil, TYPE_SPELL + TYPE_TRAP)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 1, 0, 0)
end

-- Effect 1: Operation to banish and negate effects
function s.rmoperation(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.Remove(tc, POS_FACEUP, REASON_EFFECT) ~= 0 then
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetTargetRange(LOCATION_ONFIELD, LOCATION_ONFIELD)
			e1:SetTarget(s.disablefilter(tc:GetOriginalCode()))
			e1:SetReset(RESET_PHASE + PHASE_END)
			Duel.RegisterEffect(e1, tp)
		end
	end
end

-- Helper function to create a disable effect
function s.disablefilter(code)
	return function(e, c)
		return c:IsOriginalCode(code)
	end
end

-- Effect 2: Target to transfer self and Xyz materials
function s.transtarget(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsFaceup() and chkc:IsType(TYPE_XYZ) and chkc:IsSetCard(0x30d) and chkc ~= e:GetHandler() end
	if chk == 0 then 
		-- Check for a valid face-up Xyz Monster of the correct set
		return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, e:GetHandler(), TYPE_XYZ, Card.IsSetCard, 0x30d)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g = Duel.SelectTarget(tp, function(c) return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x30d) end, tp, LOCATION_MZONE, 0, 1, 1, e:GetHandler())
end

-- Effect 2: Operation to transfer self and Xyz materials
function s.transoperation(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- Transfer this card's Xyz materials to the target
		local og = c:GetOverlayGroup()
		if #og > 0 then
			Duel.Overlay(tc, og)
		end
		-- Transfer this card itself as Xyz material
		Duel.Overlay(tc, Group.FromCards(c))
	end
end
