--일족이 잠든 기둥
local s,id=GetID()
function c128220149.initial_effect(c)
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_FZONE)
    e1:SetCountLimit(1, id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_BATTLE_START)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCondition(s.tgcon)
    e2:SetTarget(s.tgtg)
    e2:SetOperation(s.tgop)
    c:RegisterEffect(e2)
end
s.setname = 0xc27
function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
    return not c:IsSetCard(s.setname)
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
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
function s.spfilter(c, e, tp)
    return c:IsSetCard(s.setname) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE)
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
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP_DEFENSE)
    end
end
function s.tgcon(e, tp, eg, ep, ev, re, r, rp)
    local a = Duel.GetAttacker()
    local d = Duel.GetAttackTarget()
    if not d then return false end 
    if a:IsControler(tp) and a:IsSetCard(s.setname) then
        e:SetLabelObject(d)
        return true
    elseif d:IsControler(tp) and d:IsSetCard(s.setname) then
        e:SetLabelObject(a)
        return true
    end
    return false
end
function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local tc = e:GetLabelObject()
    if chk == 0 then return tc and tc:IsControler(1 - tp) and tc:IsAbleToGrave() end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, tc, 1, 0, 0)
end
function s.tgop(e, tp, eg, ep, ev, re, r, rp)
    local tc = e:GetLabelObject()
    if tc:IsRelateToBattle() then
        Duel.SendtoGrave(tc, REASON_EFFECT)
    end
end
