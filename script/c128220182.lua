--비르투스 더 퍼스트 바이올린
local s,id=GetID()
function c128220182.initial_effect(c)
	local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ②번 효과: 배틀 페이즈 개시 시, 배틀 종료시까지 마/함 발동 봉쇄
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(TIMING_BATTLE_START, TIMING_BATTLE_START)
    e2:SetCountLimit(1, {id, 1})
    e2:SetCondition(s.actcon)
    e2:SetOperation(s.actop)
    c:RegisterEffect(e2)

    -- ③번 효과: 이 턴에 묘지로 보내졌을 경우, 엔드 페이즈에 묘지의 다른 "비르투스" 회수
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_PHASE + PHASE_END)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1, {id, 2})
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)

    -- ③번 효과의 '이 턴에 묘지로 보내졌을 경우'를 감지하기 위한 턴 플래그 등록
    local e3_reg = Effect.CreateEffect(c)
    e3_reg:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e3_reg:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3_reg:SetCode(EVENT_TO_GRAVE)
    e3_reg:SetOperation(s.regop)
    c:RegisterEffect(e3_reg)
end

-- ==================== ①번 효과 루틴 ====================
function s.setfilter(c)
    return c:IsSetCard(0xc29) and c:IsSpellTrap() and c:IsSSetable(ignore)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
        and Duel.IsExistingMatchingCard(s.setfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
        local g = Duel.SelectMatchingCard(tp, s.setfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
        if #g > 0 then
            Duel.SSet(tp, g:GetFirst())
        end
    end
end

-- ==================== ②번 효과 루틴 ====================
function s.actcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_BATTLE_START
end

function s.actop(e, tp, eg, ep, ev, re, r, rp)
    -- 자신 및 상대방에게 마법/함정 카드 및 효과 발동 불가 제약 적용
    local e1 = Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1, 1)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE + PHASE_BATTLE, 1)
    Duel.RegisterEffect(e1, tp)
    
    -- 발동 제약 중임을 플레이어에게 인게임 텍스트 힌트로 시각화
    local e2 = Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_CLIENT_HINT)
    e2:SetDescription(aux.Stringid(id, 3)) -- "배틀 페이즈 종료시까지 마법/함정의 효과를 발동할 수 없다" 문구 매칭용
    e2:SetTargetRange(1, 1)
    e2:SetReset(RESET_PHASE + PHASE_BATTLE, 1)
    Duel.RegisterEffect(e2, tp)
end

function s.aclimit(e, re, tp)
    return re:IsHasCategory(CATEGORY_ANNOUNCE) or re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end

-- ==================== ③번 효과 루틴 ====================
function s.regop(e, tp, eg, ep, ev, re, r, rp)
    -- 묘지로 보내진 턴 동안 유효한 플래그(id)를 카드 자체에 등록
    e:GetHandler():RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
  local c=e:GetHandler()
	return c:GetTurnID()==Duel.GetTurnCount() and not c:IsReason(REASON_RETURN)
end

function s.thfilter(c)
    return c:IsSetCard(0xc29) and c:IsAbleToHand() and not c:IsCode(id)
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
