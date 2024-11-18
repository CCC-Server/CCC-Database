local s, id = GetID()
function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), 7, 2, nil, nil, 99)
	c:EnableReviveLimit()

	-- Remove 1 Xyz Material during the opponent's End Phase
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE + PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.rmcon)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- Gain effects based on the number of Xyz Materials
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(s.atkcon)
	e2:SetValue(1000)
	c:RegisterEffect(e2)

	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1, id)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)

	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.immcon)
	e4:SetValue(s.immfilter)
	c:RegisterEffect(e4)

	local e5 = Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id, 1))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1, id + 1)
	e5:SetCondition(s.rmcon2)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop2)
	c:RegisterEffect(e5)

	local e6 = Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id, 2))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_ATTACK_ANNOUNCE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.rmcon3)
	e6:SetOperation(s.rmop3)
	c:RegisterEffect(e6)
end

-- Remove 1 Xyz Material during the opponent's End Phase
function s.rmcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetTurnPlayer() ~= tp
end

function s.rmop(e, tp, eg, ep, ev, re, r, rp)
	if e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) then
		e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
	end
end

-- Gain 1000 ATK if 1 or more Xyz Materials
function s.atkcon(e)
	return e:GetHandler():GetOverlayCount() >= 1
end

-- Destroy 1 card if 2 or more Xyz Materials
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():GetOverlayCount() >= 2
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() end
	if chk == 0 then return Duel.IsExistingTarget(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end

-- Immune to other card effects if 3 or more Xyz Materials
function s.immcon(e)
	return e:GetHandler():GetOverlayCount() >= 3
end

function s.immfilter(e, te)
	return te:GetOwner() ~= e:GetOwner()
end

-- Banish 1 card if 4 or more Xyz Materials
function s.rmcon2(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():GetOverlayCount() >= 4
end

function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectTarget(tp, Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 1, 0, 0)
end

function s.rmop2(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc, POS_FACEUP, REASON_EFFECT)
	end
end

-- Banish all cards on opponent's field if 5 or more Xyz Materials
function s.rmcon3(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():GetOverlayCount() >= 5
end

function s.rmop3(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, nil)
	if #g > 0 then
		Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
	end
end
