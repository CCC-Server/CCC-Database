--JJ-법황의 결계
local s,id=GetID()
function c128220136.initial_effect(c)
	local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCondition(s.token_con)
    e1:SetTarget(s.token_tg)
    e1:SetOperation(s.token_op)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_DISABLE)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.negate_con)
    e2:SetTarget(s.negate_tg)
    e2:SetOperation(s.negate_op)
    c:RegisterEffect(e2)
end

-- 상수 설정
s.monster_code = 128220127 -- JJ-하이어로펀트 그린
s.token_code = 128220137   -- 법황의 결계 토큰 코드 (DB에 맞게 조정 필요)

-- 1번 효과 조건: 필드에 하이어로펀트 그린 존재 + 상대 마법 발동
function s.token_con(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and re:IsActiveType(TYPE_SPELL) 
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, s.monster_code), tp, LOCATION_ONFIELD, 0, 1, nil)
end

function s.token_tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 
        and Duel.IsPlayerCanSpecialSummonMonster(tp, s.token_code, 0, TYPES_TOKEN, 0, 0, 1, RACE_AQUA, ATTRIBUTE_WIND) end
    Duel.SetOperationInfo(0, CATEGORY_TOKEN, nil, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, 0)
end

function s.token_op(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 
        or not Duel.IsPlayerCanSpecialSummonMonster(tp, s.token_code, 0, TYPES_TOKEN, 0, 0, 1, RACE_AQUA, ATTRIBUTE_WIND) then return end
    
    local token = Duel.CreateToken(tp, s.token_code)
    if Duel.SpecialSummon(token, 0, tp, tp, false, false, POS_FACEUP_DEFENSE) > 0 then
        -- 엑스트라 덱 소재 불가
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        token:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
        token:RegisterEffect(e2)
        local e3 = e1:Clone()
        e3:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
        token:RegisterEffect(e3)
        local e4 = e1:Clone()
        e4:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
        token:RegisterEffect(e4)
        -- 어드밴스 소환을 위한 릴리스 불가
        local e5 = e1:Clone()
        e5:SetCode(EFFECT_UNRELEASABLE_SUM)
        token:RegisterEffect(e5)
    end
end

-- 2번 효과 조건: 자신 필드의 법황의 결계 토큰이 파괴됨
function s.negate_filter(c, tp)
    return c:IsPreviousControler(tp) and c:IsCode(s.token_code) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.negate_con(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.negate_filter, 1, nil, tp)
end

function s.negate_tg(e, tp, eg, ep, ev, re, r, rp, chk, chkcell)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.negate_op(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
        local c = e:GetHandler()
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e2)
    end
end