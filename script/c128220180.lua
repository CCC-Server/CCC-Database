--비르투스 펜틸호른
local s,id=GetID()
function c128220180.initial_effect(c)
    -- ①번 효과: 서로의 스탠바이 페이즈에 패에서 특수 소환
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetHintTiming(TIMING_STANDBY_PHASE, TIMING_STANDBY_PHASE)
    e1:SetCountLimit(1, id) -- ①번 효과 제약
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ②번 효과: 상대 메인 페이즈에 싱크로 또는 엑시즈 소환
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
    e2:SetCountLimit(1, {id, 1}) -- ②번 효과 제약
    e2:SetCondition(s.sccon)
    e2:SetTarget(s.sctg)
    e2:SetOperation(s.scop)
    c:RegisterEffect(e2)

    -- ③번 효과: 자신의 배틀 페이즈에 원래 공격력만큼 데미지
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetHintTiming(TIMING_BATTLE_START, TIMING_BATTLE_END)
    e3:SetCountLimit(1, {id, 2}) -- ③번 효과 제약
    e3:SetCondition(s.damcon)
    e3:SetTarget(s.damtg)
    e3:SetOperation(s.damop)
    c:RegisterEffect(e3)

    -- ④번 효과: 자신/상대 엔드 페이즈에 패 1장 버리고 묘지에서 회수
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 3))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetHintTiming(TIMING_END_PHASE, TIMING_END_PHASE)
    e4:SetCountLimit(1, {id, 3}) -- ④번 효과 제약
    e4:SetCondition(s.thcon)
    e4:SetCost(s.thcost)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
end

-- ==================== ①번 효과 루틴 ====================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_STANDBY
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

-- ==================== ②번 효과 루틴 ====================
function s.sccon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() ~= tp and (Duel.GetCurrentPhase() == PHASE_MAIN1 or Duel.GetCurrentPhase() == PHASE_MAIN2)
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
        op = Duel.SelectOption(tp, aux.Stringid(id, 4), aux.Stringid(id, 5)) -- 4: 싱크로 소환, 5: 엑시즈 소환 선택 문구
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

-- ==================== ③번 효과 루틴 ====================
function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() == tp and (Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE)
end

function s.damtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local atk = e:GetHandler():GetTextAttack()
    if atk < 0 then atk = 0 end
    Duel.SetTargetPlayer(1-tp)
    Duel.SetTargetParam(atk)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1-tp, atk)
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
        local atk = c:GetTextAttack()
        if atk > 0 then
            Duel.Damage(p, atk, REASON_EFFECT)
        end
    end
end

-- ==================== ④번 효과 루틴 ====================
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_END
end

function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsAbleToHand() end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, e:GetHandler(), 1, 0, 0)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c, nil, REASON_EFFECT)
    end
end