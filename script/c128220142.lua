--어둠의 일족 에시디시
local s,id=GetID()
function c128220142.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SUMMON_PROC)
    e1:SetCondition(s.ntcon)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetValue(1)
    c:RegisterEffect(e2)
    local e2b = e2:Clone()
    e2b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e2b)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1, id)
    e3:SetCost(s.limcost)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
    local e3b = e3:Clone()
    e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3b)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_DESTROY + CATEGORY_DAMAGE)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetCost(s.limcost)
    e4:SetTarget(s.destg)
    e4:SetOperation(s.desop)
    c:RegisterEffect(e4)
end
s.setname = 0xc27
function s.limcost(e, tp, eg, ep, ev, re, r, rp, chk)
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

function s.splimit(e, c)
    return not c:IsSetCard(s.setname)
end
function s.ntcon(e, c, minc)
    if c == nil then return true end
    return minc == 0 and Duel.GetLocationCount(c:GetControler(), LOCATION_MZONE) > 0
end
function s.thfilter(c)
    return c:IsSetCard(s.setname) and c:IsType(TYPE_TRAP) and c:IsAbleToHand()
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
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) end
    if chk == 0 then return Duel.IsExistingTarget(nil, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        local atk = 0
        if tc:IsFaceup() then atk = tc:GetAttack() end
        
        if Duel.Destroy(tc, REASON_EFFECT) ~= 0 and atk > 0 then
            Duel.Damage(1 - tp, math.floor(atk / 2), REASON_EFFECT)
        end
    end
end