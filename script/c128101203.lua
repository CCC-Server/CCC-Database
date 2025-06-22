--누밸즈 싱크로 펜듈럼 몬스터
local s,id=GetID()
function s.initial_effect(c)
    -- 펜듈럼 소환
    Pendulum.AddProcedure(c)
    -- 싱크로 소환 조건 (튜너 + 튜너 이외 몬스터 1장)
    Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1)
    c:EnableReviveLimit()

    -------------------------------------
    -- 펜듈럼 효과: 필드 발동 몬스터 무효화 + 자폭 (퍼미션)
    -------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_CHAIN_SOLVING)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCondition(s.discon)
    e1:SetOperation(s.disop)
    c:RegisterEffect(e1)

    -------------------------------------
    -- 몬스터 효과 ①: 특수 소환 성공 시 (강제) - 주인의 덱에서 특수 소환
    -------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.sptg1)
    e2:SetOperation(s.spop1)
    c:RegisterEffect(e2)

    -------------------------------------
    -- 몬스터 효과 ②: 상대가 의식 몬스터 특소 시, 공격력 +1000 (강제, 대상 지정)
    -------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.atkcon)
    e3:SetTarget(s.atktg)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)

    -------------------------------------
    -- 몬스터 효과 ③: 릴리스되어 엑덱에 앞면으로 갔을 때 펜듈럼존 이동
    -------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_MOVE)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCountLimit(1,{id,3})
    e4:SetCondition(s.pzcon)
    e4:SetTarget(s.pztg)
    e4:SetOperation(s.pzop)
    c:RegisterEffect(e4)
end
s.listed_series={0x197} -- "누밸즈" 시리즈

---------------------------------------------------
-- 펜듈럼 효과: 무효 + 자폭 (퍼미션)
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
        and re:GetHandler():IsOnField()
        and Duel.IsChainDisablable(ev)
        and Duel.IsExistingMatchingCard(function(c)
            return c:IsFaceup() and c:IsSetCard(0x197) and c:IsType(TYPE_RITUAL)
        end,tp,LOCATION_MZONE,0,1,nil)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.NegateEffect(ev) and c:IsOnField() and c:IsDestructable() then
        Duel.BreakEffect()
        Duel.Destroy(c,REASON_EFFECT)
    end
end

---------------------------------------------------
-- 특수 소환 성공 시: 덱에서 "누밸즈" 의식 몬스터 소환
function s.spfilter1(c,e,tp)
    return c:IsSetCard(0x197) and c:IsType(TYPE_RITUAL)
        and (c:IsLevel(1) or c:IsLevel(2))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,true)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    local p=e:GetHandler():GetOwner()
    if chk==0 then
        return Duel.GetLocationCount(p,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter1,p,LOCATION_DECK,0,1,nil,e,p)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,p,LOCATION_DECK)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local p=e:GetHandler():GetOwner()
    if Duel.GetLocationCount(p,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,p,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(p,s.spfilter1,p,LOCATION_DECK,0,1,1,nil,e,p)
    if #g>0 then
        Duel.SpecialSummon(g,0,p,p,false,true,POS_FACEUP)
    end
end

---------------------------------------------------
-- 상대가 의식 몬스터 특소 시: 대상에게 +1000
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(c) return c:IsSummonPlayer(1-tp) and c:IsType(TYPE_RITUAL) end,1,nil)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return eg:IsContains(chkc) and chkc:IsFaceup() and chkc:IsType(TYPE_RITUAL) end
    if chk==0 then return eg:IsExists(function(c) return c:IsFaceup() and c:IsType(TYPE_RITUAL) end,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local tg=eg:FilterSelect(tp,function(c) return c:IsFaceup() and c:IsType(TYPE_RITUAL) end,1,1,nil)
    Duel.SetTargetCard(tg)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

---------------------------------------------------
-- 릴리스되어 엑덱 앞면으로 이동 시, 펜듈럼존으로
function s.pzcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsLocation(LOCATION_EXTRA)
        and c:IsFaceup() and c:IsReason(REASON_RELEASE)
end
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckPendulumZones(tp) end
end
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.CheckPendulumZones(tp) then
        Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
    end
end
