--비르투스 피코플루트
local s,id=GetID()
function c128220181.initial_effect(c)
	local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE) -- 필드발동 (묘지로 보내고 발동하므로 필드 상정)
    e1:SetHintTiming(TIMING_STANDBY_PHASE, TIMING_STANDBY_PHASE)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.spcon1)
    e1:SetCost(s.spcost1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)

    -- ②번 효과: 자신 메인 페이즈에 패에서 특소 + "비르투스" 서치
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1, {id, 1})
    e2:SetTarget(s.sptg2)
    e2:SetOperation(s.spop2)
    c:RegisterEffect(e2)

    -- ③번 효과: 서로의 배틀 페이즈에 "비르투스" 몬스터 공 1000 업
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetHintTiming(TIMING_BATTLE_START, TIMING_BATTLE_END)
    e3:SetCountLimit(1, {id, 2})
    e3:SetCondition(s.atkcon)
    e3:SetTarget(s.atktg)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)

    -- ④번 효과: 자신/상대 엔드 페이즈에 1장 드로우 후 패 1장 덱 맨 아래로
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 3))
    e4:SetCategory(CATEGORY_DRAW)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetHintTiming(TIMING_END_PHASE, TIMING_END_PHASE)
    e4:SetCountLimit(1, {id, 3})
    e4:SetCondition(s.drcon)
    e4:SetTarget(s.drtg)
    e4:SetOperation(s.drop)
    c:RegisterEffect(e4)
end

-- ==================== ①번 효과 루틴 ====================
function s.spcon1(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_STANDBY
end

function s.spfilter1(c, e, tp)
    return c:IsLevelBelow(5) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.spcost1(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsAbleToGraveAsCost() end
    Duel.SendtoGrave(e:GetHandler(), REASON_COST)
end

function s.sptg1(e, tp, eg, ep, ev, re, r, rp, chk, chkcl)
    if chk == 0 then
        -- 코스트로 필드의 이 카드가 빠지므로 구역 수 계산 시 (ft > 0) 보정 체크 필요
        if chkcl == 0 and Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return false end
        return Duel.IsExistingTarget(s.spfilter1, tp, LOCATION_GRAVE, 0, 1, nil, e, tp)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectTarget(tp, s.spfilter1, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

function s.spop1(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- ==================== ②번 효과 루틴 ====================
function s.thfilter(c)
    return c:IsSetCard(0xc29) and c:IsMonster() and c:IsAbleToHand()
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
        and Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
        if #g > 0 then
            Duel.SendtoHand(g, nil, REASON_EFFECT)
            Duel.ConfirmCards(1-tp, g)
        end
    end
end

-- ==================== ③번 효과 루틴 ====================
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE
end

function s.atkfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xc29)
end

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.atkfilter, tp, LOCATION_MZONE, 0, 1, nil) end
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.atkfilter, tp, LOCATION_MZONE, 0, nil)
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end

-- ==================== ④번 효과 루틴 ====================
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_END
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsPlayerCanDraw(tp, 1) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
    local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
    if Duel.Draw(p, d, REASON_EFFECT) > 0 then
        Duel.ShuffleHand(tp)
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
        local g = Duel.SelectMatchingCard(tp, Card.IsAbleToDeckAsCost, tp, LOCATION_HAND, 0, 1, 1, nil)
        if #g > 0 then
            Duel.SendtoDeck(g, nil, SEQ_DECKBOTTOM, REASON_EFFECT)
        end
    end
end
