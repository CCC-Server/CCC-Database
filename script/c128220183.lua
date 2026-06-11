--비르투스 비올론첼로
local s,id=GetID()
function c128220183.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE) -- 필드 발동 상정
    e1:SetHintTiming(TIMING_STANDBY_PHASE, TIMING_STANDBY_PHASE)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)

    -- ②번 효과: 자신 메인 페이즈에 패에서 특소 + 필드의 카드 1장 효과 무효
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DISABLE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1, {id, 1})
    e2:SetTarget(s.sptg2)
    e2:SetOperation(s.spop2)
    c:RegisterEffect(e2)

    -- ③번 효과: 서로의 배틀 페이즈에 싱크로 또는 엑시즈 소환 실행
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetHintTiming(TIMING_BATTLE_START, TIMING_BATTLE_END)
    e3:SetCountLimit(1, {id, 2})
    e3:SetCondition(s.sccon)
    e3:SetTarget(s.sctg)
    e3:SetOperation(s.scop)
    c:RegisterEffect(e3)
end

-- ==================== ①번 효과 루틴 ====================
function s.spcon1(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_STANDBY
end

function s.spfilter1(c, e, tp)
    return c:IsSetCard(0xc29) and c:IsMonster() and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg1(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter1, tp, LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop1(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter1, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- ==================== ②번 효과 루틴 ====================
function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk, chkcl)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false)
        and Duel.IsExistingTarget(Card.IsNegatable, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_NEGATE)
    local g = Duel.SelectTarget(tp, Card.IsNegatable, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        local tc = Duel.GetFirstTarget()
        if tc and tc:IsRelateToEffect(e) and tc:IsCanBeDisabledByEffect(e) then
             Duel.BreakEffect()
             local e1 = Effect.CreateEffect(c)
             e1:SetType(EFFECT_TYPE_SINGLE)
             e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
             e1:SetCode(EFFECT_DISABLE)
             e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
             tc:RegisterEffect(e1)
             if tc:IsType(TYPE_TRAPMONSTER) or tc:IsSpellTrap() then
                 local e2 = Effect.CreateEffect(c)
                 e2:SetType(EFFECT_TYPE_SINGLE)
                 e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                 e2:SetCode(EFFECT_DISABLE_EFFECT)
                 e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                 tc:RegisterEffect(e2)
             end
        end
    end
end

-- ==================== ③번 효과 루틴 ====================
function s.sccon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE
end

function s.sctg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local syn = Duel.IsExistingMatchingCard(Card.IsSynchroSummonable, tp, LOCATION_EXTRA, 0, 1, nil, e:GetHandler())
        local xyz = Duel.IsExistingMatchingCard(Card.IsXyzSummonable, tp, LOCATION_EXTRA, 0, 1, nil, e:GetHandler())
        return syn or xyz
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.scop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsControler(1-tp) then return end
    
    local syn = Duel.IsExistingMatchingCard(Card.IsSynchroSummonable, tp, LOCATION_EXTRA, 0, 1, nil, c)
    local xyz = Duel.IsExistingMatchingCard(Card.IsXyzSummonable, tp, LOCATION_EXTRA, 0, 1, nil, c)
    
    local op = 0
    if syn and xyz then
        op = Duel.SelectOption(tp, aux.Stringid(id, 3), aux.Stringid(id, 4)) -- 3: 싱크로 소환, 4: 엑시즈 소환 선택 UI
    elseif syn then
        op = 0
    elseif xyz then
        op = 1
    else
        return
    end
    
    if op == 0 then
        local g = Duel.GetMatchingGroup(Card.IsSynchroSummonable, tp, LOCATION_EXTRA, 0, nil, c)
        if #g > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sg = g:Select(tp, 1, 1, nil)
            Duel.SynchroSummon(tp, sg:GetFirst(), c)
        end
    else
        local g = Duel.GetMatchingGroup(Card.IsXyzSummonable, tp, LOCATION_EXTRA, 0, nil, c)
        if #g > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sg = g:Select(tp, 1, 1, nil)
            Duel.XyzSummon(tp, sg:GetFirst(), c)
        end
    end
end
