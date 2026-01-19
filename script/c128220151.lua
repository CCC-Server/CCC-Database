--에이자의 적석
local s,id=GetID()
function c128220151.initial_effect(c)
local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    e0:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
    e0:SetTarget(s.acttg)
    c:RegisterEffect(e0)

    -- ①: 공격력 1500 증가 및 효과 무효화
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_SZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1, id) -- ①번 효과 1턴에 1번
    e1:SetTarget(s.atktg)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)

    -- ②: 묘지에서 필드에 세트
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1, id + 1) -- ②번 효과 1턴에 1번
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

-- ①번 효과 관련: 함정 발동 시에도 효과를 쓸 수 있게 설정
function s.acttg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return s.atktg(e, tp, eg, ep, ev, re, r, rp, 0, chkc) end
    if chk == 0 then return true end
    if s.atktg(e, tp, eg, ep, ev, re, r, rp, 0) and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
        e:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DISABLE)
        e:SetProperty(EFFECT_FLAG_CARD_TARGET)
        e:SetOperation(s.atkop)
        s.atktg(e, tp, eg, ep, ev, re, r, rp, 1)
        e:GetHandler():RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
        -- 함정 발동 시 효과를 썼다면 ①번 효과의 횟수를 소모함
        Duel.SetOperationInfo(0, CATEGORY_DISABLE, nil, 1, 0, 0)
    else
        e:SetCategory(0)
        e:SetProperty(0)
        e:SetOperation(nil)
    end
end

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
    -- 함정 발동 시 카운트 리미트 수동 체크 (FlagEffect 사용)
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) 
        and (e:GetHandler():GetFlagEffect(id) == 0 or e:IsHasType(EFFECT_TYPE_ACTIVATE)) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) and not e:IsHasType(EFFECT_TYPE_ACTIVATE) then return end
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local c = e:GetHandler()
        -- 공격력 1500 증가
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        
        -- 효과 무효화
        Duel.NegateRelatedChain(tc, RESET_TURN_SET)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e2)
        local e3 = Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_DISABLE_EFFECT)
        e3:SetValue(RESET_TURN_SET)
        e3:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e3)
    end
end

-- ②번 효과 관련
function s.lvl5illusionfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_ILLUSION) and c:IsLevelAbove(5)
end

function s.setcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(s.lvl5illusionfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsSSetable() end
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, e:GetHandler(), 1, 0, 0)
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsSSetable() then
        Duel.SSet(tp, c)
    end
end
