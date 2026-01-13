--JJ-더 풀
local s,id=GetID()
function c128220131.initial_effect(c)
Xyz.AddProcedure(c, nil, 3, 5)
    c:EnableReviveLimit()
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(1000)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_ONFIELD, 0)
    e2:SetCondition(s.tgcon)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xc26))
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_DAMAGE_STEP_END)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end
s.listed_names = { 128220125 }
s.listed_series = { 0xc26 }
function s.tgcon(e)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsCode(128220125)
end
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and (Duel.GetAttacker() == ec or Duel.GetAttackee() == ec)
end
function s.thfilter(c)
    return c:IsSetCard(0xc26) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_GRAVE)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end