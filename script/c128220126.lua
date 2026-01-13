--JJ-스타 플래티나
local s,id=GetID()
function c128220126.initial_effect(c)
    Xyz.AddProcedure(c, nil, 7, 5)
    c:EnableReviveLimit()
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(1000)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_CHAIN_SOLVING)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCondition(s.discon)
    e2:SetOperation(s.disop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end
function s.discon(e, tp, eg, ep, ev, re, r, rp)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsCode(128220120) and rp ~= tp 
        and Duel.GetFlagEffect(tp, id) == 0
end
function s.disop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
	if Duel.GetFlagEffect(tp,id)==0 and Duel.SelectEffectYesNo(tp,e:GetHandler()) then
    Duel.RegisterFlagEffect(tp, id, RESET_PHASE + PHASE_END, 0, 1)
    Duel.Hint(HINT_CARD, 0, id)
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, c)
    local tc = g:GetFirst()
    while tc do
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e2)
        tc = g:GetNext()
    end
	end
end
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsCode(128220120) 
end

function s.thfilter(c)
    return c:IsSetCard(0xc26) and c:IsType(TYPE_SPELL) and c:IsAbleToHand() 
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