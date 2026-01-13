--JJ-하이어로펀트 그린
local s,id=GetID()
function c128220127.initial_effect(c)
    Xyz.AddProcedure(c,nil,7,5)
    c:EnableReviveLimit()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_DEFENSE)
    e1:SetValue(1000)
    c:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end
function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:GetEquipTarget() and eg:IsExists(Card.IsControler, 1, nil, tp) end
    return Duel.SelectEffectYesNo(tp, c, 96) 
end
function s.repval(e, c)
    return c:IsControler(e:GetHandlerPlayer())
end
function s.repop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESREPLACE)
    local g = Duel.SelectMatchingCard(tp, nil, tp, LOCATION_ONFIELD, 0, 1, 1, nil)
    if #g > 0 then
        Duel.Destroy(g, REASON_EFFECT + REASON_REPLACE)
    end
end
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsCode(128220121) 
end
function s.thfilter(c)
    return c:IsSetCard(0xc26) and c:IsType(TYPE_TRAP) and c:IsAbleToHand()
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