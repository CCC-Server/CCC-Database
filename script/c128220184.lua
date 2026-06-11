--비르투스 스트링베이스
local s,id=GetID()
function c128220184.initial_effect(c)
	local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TOGRAVE + CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ②번 효과: 상대 배틀 페이즈에 묘지의 이 카드를 제외하고 배틀 페이즈 종료
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetHintTiming(TIMING_BATTLE_START + TIMING_BATTLE_END)
    e2:SetCountLimit(1, {id, 1})
    e2:SetCondition(s.bpcon)
    e2:SetCost(s.bpcost)
    e2:SetOperation(s.bpop)
    c:RegisterEffect(e2)

    -- ③번 효과: 서로의 엔드 페이즈에 묘지의 "비르투스" 카드 1장을 패에 넣는다.
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_PHASE + PHASE_END)
    e3:SetRange(LOCATION_MZONE) -- 필드 상정 (필요에 따라 LOCATION_GRAVE 등 추가 가능)
    e3:SetCountLimit(1, {id, 2})
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- ==================== ①번 효과 루틴 ====================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() == tp -- 자신의 턴 확인
end

function s.tgfilter(c)
    return c:IsSetCard(0xc29) and c:IsMonster() and not c:IsCode(id) and c:IsAbleToGrave()
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
        and Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_DECK)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g = Duel.SelectMatchingCard(tp, s.tgfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
        local c = e:GetHandler()
        if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
            Duel.BreakEffect()
            Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end

-- ==================== ②번 효과 루틴 ====================
function s.bpcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() ~= tp and (Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE)
end

function s.bpcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c, POS_FACEUP, REASON_COST)
end

function s.bpop(e, tp, eg, ep, ev, re, r, rp)
    Duel.SkipPhase(1-tp, PHASE_BATTLE, RESET_PHASE + PHASE_BATTLE, 1)
end

-- ==================== ③번 효과 루틴 ====================
function s.thfilter(c)
    return c:IsSetCard(0xc29) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_GRAVE)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1-tp, g)
    end
end
