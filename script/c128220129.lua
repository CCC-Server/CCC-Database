--JJ-매지션즈 레드
local s,id=GetID()
function c128220129.initial_effect(c)
Xyz.AddProcedure(c, nil, 7, 5)
	c:EnableReviveLimit()
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.tgcon)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.ctcon)
	e3:SetOperation(s.ctop)
	c:RegisterEffect(e3)
end
local COUNTER_CFH = 0x1101 
function s.atkval(e, c)
	return e:GetHandler():GetCounter(COUNTER_CFH) * 300
end
function s.tgcon(e, tp, eg, ep, ev, re, r, rp)
	local ec = e:GetHandler():GetEquipTarget()
	return ec and ec:IsCode(128220123)
end
function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGrave, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, 0, 0)
end

function s.tgop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, Card.IsAbleToGrave, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	if #g > 0 then
		Duel.HintSelection(g)
		Duel.SendtoGrave(g, REASON_EFFECT)
	end
end
function s.ctcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():GetEquipTarget() ~= nil 
		and eg:IsExists(Card.IsPreviousLocation, 1, nil, LOCATION_ONFIELD)
end

function s.ctop(e, tp, eg, ep, ev, re, r, rp)
	e:GetHandler():AddCounter(COUNTER_CFH, 1)
end