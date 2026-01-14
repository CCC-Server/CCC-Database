--JJ-이기
local s,id=GetID()
function c128220125.initial_effect(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_EQUIP + CATEGORY_POSITION)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.eqtg)
    e1:SetOperation(s.eqop)
    c:RegisterEffect(e1)
    local e1b = e1:Clone()
    e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e1b)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,{id,1}) 
	e2:SetCost(Cost.SelfDiscard)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_DIRECT_ATTACK)
    e3:SetCondition(s.dircon)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_DEFENSE_ATTACK)
    e4:SetValue(0)
    c:RegisterEffect(e4)
end
function s.eqfilter(c)
    return c:IsCode(128220131)
end
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingMatchingCard(s.eqfilter, tp, LOCATION_EXTRA + LOCATION_GRAVE, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, nil, 1, tp, LOCATION_EXTRA + LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_POSITION, e:GetHandler(), 1, 0, 0)
end
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or c:IsFacedown() or not c:IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectMatchingCard(tp, s.eqfilter, tp, LOCATION_EXTRA + LOCATION_GRAVE, 0, 1, 1, nil)
    local tc = g:GetFirst()
    if tc then
        if Duel.Equip(tp, tc, c) then
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_COPY_INHERIT + EFFECT_FLAG_OWNER_RELATE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetValue(s.eqlimit)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
            Duel.BreakEffect()
            Duel.ChangePosition(c, POS_FACEUP_DEFENSE)
        end
    end
end
function s.eqlimit(e, c)
    return e:GetOwner() == c
end

-- ②번 효과 함수
function s.thfilter(c)
    return c:IsSetCard(0xc26) and c:IsAbleToHand() 
end
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsAbleToGraveAsCost() end
    Duel.SendtoGrave(e:GetHandler(), REASON_COST + REASON_DISCARD)
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

-- ③번 효과 함수
function s.dircon(e)
    return e:GetHandler():GetEquipCount() > 0
end