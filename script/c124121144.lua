-- 칸티고 바르카르
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 메인 페이즈에 패를 공개하고 타겟 공격력 증가 및 서치
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.con1)
    e1:SetCost(s.cost1)
    e1:SetTarget(s.tg1)
    e1:SetOperation(s.op1)
    c:RegisterEffect(e1)
    
    -- ②: 패에서 공개 중일 때 특수 소환 (룰 소환)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_HAND)
    e2:SetCondition(s.spcon)
    c:RegisterEffect(e2)
    
    -- ②: 패에서 공개 중일 때 레벨 5/10 몬스터 내성
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetRange(LOCATION_HAND)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetCondition(s.pubcon)
    e3:SetTarget(function(e,c) return c:IsFaceup() and (c:IsLevel(5) or c:IsLevel(10)) end)
    e3:SetValue(function(e,te) return te:IsActiveType(TYPE_MONSTER) and te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated() end)
    c:RegisterEffect(e3)
end

-- [① 효과 구현]
function s.con1(e,tp,eg,ep,ev,re,r,rp) local ph=Duel.GetCurrentPhase() return ph==PHASE_MAIN1 or ph==PHASE_MAIN2 end
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return not c:IsPublic() end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_PUBLIC)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
end
function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() and chkc:IsLevelAbove(5) end
    if chk==0 then return Duel.IsExistingTarget(function(c) return c:IsFaceup() and c:IsLevelAbove(5) end,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
        and Duel.IsExistingMatchingCard(function(c) return c:IsRace(RACE_WARRIOR) and c:IsLevel(5) and c:IsAbleToHand() end,tp,LOCATION_DECK,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,function(c) return c:IsFaceup() and c:IsLevelAbove(5) end,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.op1(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,function(c) return c:IsRace(RACE_WARRIOR) and c:IsLevel(5) and c:IsAbleToHand() end,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then Duel.BreakEffect(); Duel.SendtoHand(g,nil,REASON_EFFECT); Duel.ConfirmCards(1-tp,g) end
    end
end

-- [② 효과 구현]
function s.pubcon(e) return e:GetHandler():IsPublic() end
function s.spcon(e,c)
    if c==nil then return true end
    return e:GetHandler():IsPublic() and Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
end