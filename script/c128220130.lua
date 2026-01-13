--JJ-허밋 퍼플
local s,id=GetID()
function c128220130.initial_effect(c)
c:EnableReviveLimit()
    Xyz.AddProcedure(c, nil, 7, 5)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_DEFENSE)
    e1:SetValue(700)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1, id)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_DRAW)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.chkon)
    e3:SetOperation(s.chkop)
    c:RegisterEffect(e3)
end
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsCode(128220124)
end
function s.thfilter(c)
    return c:IsSetCard(0xc26) and c:IsAbleToHand() 
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
function s.chkon(e, tp, eg, ep, ev, re, r, rp)
    return ep ~= tp and Duel.GetCurrentPhase() ~= PHASE_DRAW
	end
function s.chkop(e, tp, eg, ep, ev, re, r, rp)
    if #eg > 0 then
        Duel.ConfirmCards(tp, eg) 
        Duel.ShuffleHand(1 - tp) 
    end
end