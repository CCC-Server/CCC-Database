--어둠의 일족 산타나
local s,id=GetID()
function c128220143.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCost(s.limcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.decktg)
    e2:SetOperation(s.deckop)
    c:RegisterEffect(e2)
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
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
    end
end
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_MAIN1 or Duel.GetCurrentPhase() == PHASE_MAIN2
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return s.limcost(e, tp, eg, ep, ev, re, r, rp, 0)
        and e:GetHandler():IsReleasable() end
    s.limcost(e, tp, eg, ep, ev, re, r, rp, 1)
    Duel.Release(e:GetHandler(), REASON_COST)
end
function s.deckfilter(c, e, tp)
    return c:IsSetCard(s.setname) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.decktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1 -- 코스트로 릴리스되므로 -1부터 체크
        and Duel.IsExistingMatchingCard(s.deckfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end
function s.deckop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.deckfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end