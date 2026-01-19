--완전생물
local s,id=GetID()
function c128220145.initial_effect(c)
c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, 128220140, aux.FilterBoolFunctionEx(Card.IsRace, RACE_ILLUSION), aux.FilterBoolFunctionEx(Card.IsRace, RACE_ILLUSION), aux.FilterBoolFunctionEx(Card.IsRace, RACE_ILLUSION), aux.FilterBoolFunctionEx(Card.IsRace, RACE_ILLUSION))

    -- 특수 소환 조건 제약
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- 특수 소환 방법: 석가면을 장착한 카즈 + 에이자의 적석을 묘지로 보냄
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ①: 특수 소환은 무효화되지 않는다
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e2)

    -- ②: "어둠의 일족" 이외의 카드 효과 내성 + 전투 파괴 내성
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)
    local e4 = e3:Clone()
    e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e4:SetValue(1)
    c:RegisterEffect(e4)

    -- ③: 상대 몬스터 효과 무효 및 효과 복사
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetCategory(CATEGORY_DISABLE)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.copytg)
    e5:SetOperation(s.copyop)
    c:RegisterEffect(e5)
end
s.kars = 128220140
s.mask = 128220148
s.stone = 128220151
s.setname = 0xc27
function s.splimit(e, se, sp, st)
    return (st & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION or (se and se:GetHandler() == e:GetHandler())
end
function s.spfilter_kars(c, tp)
    return c:IsFaceup() and c:IsCode(s.kars) 
        and c:GetEquipGroup():IsExists(Card.IsCode, 1, nil, s.mask)
        and Duel.IsExistingMatchingCard(s.spfilter_stone, tp, LOCATION_ONFIELD + LOCATION_HAND, 0, 1, c)
end
function s.spfilter_stone(c)
    return c:IsCode(s.stone) and c:IsAbleToGraveAsCost()
end
function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.IsExistingMatchingCard(s.spfilter_kars, tp, LOCATION_MZONE, 0, 1, nil, tp)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g1 = Duel.GetMatchingGroup(s.spfilter_kars, tp, LOCATION_MZONE, 0, nil, tp)
    if #g1 > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sc1 = g1:Select(tp, 1, 1, nil):GetFirst()
        local g2 = Duel.GetMatchingGroup(s.spfilter_stone, tp, LOCATION_ONFIELD + LOCATION_HAND, 0, sc1)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sc2 = g2:Select(tp, 1, 1, nil):GetFirst()
        g1:Clear()
        g1:AddCard(sc1)
        g1:AddCard(sc2)
        g1:KeepAlive()
        e:SetLabelObject(g1)
        return true
    end
    return false
end
function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    if not g then return end
    Duel.SendtoGrave(g, REASON_COST)
    g:DeleteGroup()
end
function s.efilter(e, te)
    return not te:GetHandler():IsSetCard(s.setname)
end
function s.copytg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(1 - tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
end
function s.copyop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsImmuneToEffect(e) then
        -- 상대 효과 무효화
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e2)
        
        -- 효과 복사
        if c:IsRelateToEffect(e) and c:IsFaceup() then
            c:CopyEffect(tc:GetOriginalCode(), RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 1)
        end
    end
end
