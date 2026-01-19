--어둠의 일족의 유법 - 휘채활도
local s,id=GetID()
function c128220144.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
    e1:SetHintTiming(TIMING_DAMAGE_STEP)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.atkcon)
    e1:SetCost(s.atkcost)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1, id + 1)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_EQUIP)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetCondition(s.eqcon)
    e3:SetValue(1500)
    c:RegisterEffect(e3)
end
s.setname = 0xc27
s.kars = 128220140
s.ultimate = 128220145
function s.splimit(e, c)
    return not c:IsSetCard(s.setname)
end
function s.oath_effect(e, tp)
    local e1 = Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1, 0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE + PHASE_END)
    Duel.RegisterEffect(e1, tp)
end
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    local phase = Duel.GetCurrentPhase()
    if phase ~= PHASE_DAMAGE or Duel.IsDamageCalculated() then return false end
    local a = Duel.GetAttacker()
    local d = Duel.GetAttackTarget()
    return (a and a:IsControler(tp) and a:IsCode(s.kars))
        or (d and d:IsControler(tp) and d:IsCode(s.kars))
end
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsAbleToGraveAsCost() 
        and Duel.GetCustomActivityCount(id, tp, ACTIVITY_SPSUMMON) == 0 end
    s.oath_effect(e, tp)
    Duel.SendtoGrave(e:GetHandler(), REASON_COST)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local a = Duel.GetAttacker()
    local d = Duel.GetAttackTarget()
    if not a or not d then return end
    local tc = (a:IsControler(tp) and a:IsCode(s.kars)) and a or d
    local oc = (tc == a) and d or a   
    if tc:IsFaceup() and tc:IsRelateToBattle() and oc:IsFaceup() and oc:IsRelateToBattle() then
        local atk = oc:GetAttack()
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(atk)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsAbleToRemoveAsCost()
        and Duel.GetCustomActivityCount(id, tp, ACTIVITY_SPSUMMON) == 0 end
    s.oath_effect(e, tp)
    Duel.Remove(e:GetHandler(), POS_FACEUP, REASON_COST)
end
function s.spfilter(c, e, tp)
    return c:IsSetCard(s.setname) and not c:IsCode(id) 
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end
function s.eqcon(e)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and (ec:IsCode(s.kars) or ec:IsCode(s.ultimate))
end