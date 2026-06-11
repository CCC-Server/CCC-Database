--비르투스 비올라알토
local s,id=GetID()
function c128220185.initial_effect(c)
	local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DISABLE + CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.discon)
    e1:SetTarget(s.distg)
    e1:SetOperation(s.disop)
    c:RegisterEffect(e1)

    -- ②번 효과: 서로의 메인 페이즈에 패의 이 카드를 보여주고 "비르투스" 서치 후 패 1장 덱 맨 아래로
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_HAND)
    e2:SetHintTiming(TIMING_MAIN_END, TIMING_MAIN_END)
    e2:SetCountLimit(1, {id, 1})
    e2:SetCondition(s.thcon)
    e2:SetCost(s.thcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- ③번 효과: 스탠바이/메인/배틀 페이즈에 전부 효과를 발동한 턴의 엔드 페이즈에 묘지에서 회수
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_PHASE + PHASE_END)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1, {id, 2})
    e3:SetCondition(s.epcon)
    e3:SetTarget(s.eptg)
    e3:SetOperation(s.epop)
    c:RegisterEffect(e3)

    -- ③번 효과의 조건을 체크하기 위한 글로벌 턴 플래그 감지 (듀얼 전체에 영향)
    if not s.global_check then
        s.global_check = true
        local ge1 = Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_CHAINING)
        ge1:SetOperation(s.chain_check_op)
        Duel.RegisterEffect(ge1, 0)
    end
end

-- ==================== ①번 효과 루틴 ====================
function s.discon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_STANDBY and rp ~= tp and re:IsActiveType(TYPE_MONSTER)
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false) end
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, eg, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- 상대 몬스터 효과 무효 처리
    if Duel.NegateEffect(ev) and c:IsRelateToEffect(e) and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        Duel.BreakEffect()
        -- 패에서 특수 소환
        Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- ==================== ②번 효과 루틴 ====================
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_MAIN1 or Duel.GetCurrentPhase() == PHASE_MAIN2
end

function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return not c:IsPublic() end
    -- 패의 이 카드를 상대에게 보여주는 코스트
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_PUBLIC)
    e1:SetReset(RESET_CHAIN)
    c:RegisterEffect(e1)
end

function s.thfilter(c)
    return c:IsSetCard(0xc29) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 and Duel.SendtoHand(g, nil, REASON_EFFECT) > 0 then
        Duel.ConfirmCards(1-tp, g)
        Duel.ShuffleHand(tp)
        -- 그 후, 자신의 패를 1장 골라 덱 맨 아래로
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
        local tg = Duel.SelectMatchingCard(tp, Card.IsAbleToDeckAsCost, tp, LOCATION_HAND, 0, 1, 1, nil)
        if #tg > 0 then
            Duel.SendtoDeck(tg, nil, SEQ_DECKBOTTOM, REASON_EFFECT)
        end
    end
end

-- ==================== ③번 효과 및 플래그 체크 루틴 ====================
function s.chain_check_op(e, tp, eg, ep, ev, re, r, rp)
    -- 효과를 발동한 플레이어(자신)의 페이즈별 플래그를 누적 기록
    local phase = Duel.GetCurrentPhase()
    local p = rp -- 효과를 발동한 플레이어 기준 (만약 자신/상대 상관없이 유저 기준이라면 tp 사용 가능, 본 코드는 발동 유저 기준 기록)
    
    if phase == PHASE_STANDBY then
        Duel.RegisterFlagEffect(p, id + PHASE_STANDBY, RESET_PHASE + PHASE_END, 0, 1)
    elseif phase == PHASE_MAIN1 or phase == PHASE_MAIN2 then
        Duel.RegisterFlagEffect(p, id + PHASE_MAIN1, RESET_PHASE + PHASE_END, 0, 1)
    elseif phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE then
        Duel.RegisterFlagEffect(p, id + PHASE_BATTLE, RESET_PHASE + PHASE_END, 0, 1)
    end
end

function s.epcon(e, tp, eg, ep, ev, re, r, rp)
    -- 효과 발동 대상 플레이어(tp)가 오늘 턴 동안 세 페이즈 모두에서 효과를 발동했었는지 플래그 검사
    return Duel.GetFlagEffect(tp, id + PHASE_STANDBY) > 0
       and Duel.GetFlagEffect(tp, id + PHASE_MAIN1) > 0
       and Duel.GetFlagEffect(tp, id + PHASE_BATTLE) > 0
end

function s.eptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, c, 1, 0, 0)
end

function s.epop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c, nil, REASON_EFFECT)
        Duel.ConfirmCards(1-tp, c)
    end
end
