--어둠의 일족의 최종유법 - 혼설삽
local s,id=GetID()
function c128220147.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCondition(s.remcon)
    e1:SetTarget(s.remtg)
    e1:SetOperation(s.remop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1, id)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end
s.setname = 0xc27
s.wamuu = 128220141
function s.remcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, s.wamuu), tp, LOCATION_MZONE, 0, 1, nil)
end

function s.remtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(1 - tp) and chkc:IsAbleToRemoveInAfterImage() end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToRemovePointer, tp, 0, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectTarget(tp, Card.IsAbleToRemovePointer, tp, 0, LOCATION_ONFIELD, 1, 99, nil)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, #g, 0, 0)
end

function s.remop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetTargetCards(e)
    if #g > 0 then
        local count = Duel.Remove(g, POS_FACEDOWN, REASON_EFFECT)
        if count > 0 then
            Duel.BreakEffect()
            Duel.SetLP(tp,Duel.GetLP(tp)-count*2500)
        end
    end
end
function s.thfilter(c)
    return c:IsSetCard(s.setname) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
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
