--어둠의 일족 카즈
local s,id=GetID()
function c128220140.initial_effect(c)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SUMMON_PROC)
    e1:SetCondition(s.ntcon)
    c:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetValue(1)
    c:RegisterEffect(e2)
    local e2b=e2:Clone()
    e2b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e2b)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id)
    e3:SetCost(s.cost)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
    local e3b=e3:Clone()
    e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3b)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOGRAVE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,1}) -- ③번과 구분되는 제약
    e4:SetCost(s.cost)
    e4:SetTarget(s.tgtg)
    e4:SetOperation(s.tgop)
    c:RegisterEffect(e4)
end
function s.filter(c)
    return c:IsSetCard(0xc27) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetCustomActivityCount(id, tp, ACTIVITY_SPSUMMON) == 0 end
    local e1 = Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1, 0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE + PHASE_END)
    Duel.RegisterEffect(e1, tp)
end
function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
    return not c:IsSetCard(0xc27) --
end
function s.ntcon(e, c, minc)
    if c == nil then return true end
    return minc == 0 and Duel.GetLocationCount(c:GetControler(), LOCATION_MZONE) > 0
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.filter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) end
    if chk == 0 then return Duel.IsExistingTarget(nil, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, 1, 0, 0)
end
function s.tgop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc, REASON_EFFECT)
    end
end