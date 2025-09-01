--드래고니아-흑금룡 겔드라허
local s,id=GetID()
function s.initial_effect(c)
    --① 패에서 버리고 "드래고니아" 카드 1장 서치
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    
    --② 묘지에서 자신 특수 소환
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.spcost)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    --③ ②의 효과로 특수 소환했을 경우, 턴 종료시까지 튜너로 취급
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.tncon)
    e3:SetOperation(s.tnop)
    c:RegisterEffect(e3)
end

s.listed_series={0xc05}

--① 코스트 (패 버림 + 드래곤족 싱크로 제약)
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0 and c:IsDiscardable() end
    Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
    -- 이 턴 동안 드래곤족 싱크로만 엑덱 특소 가능
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,3)) -- ⚠ strings.conf에서 별도 텍스트 준비 권장
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsLocation(LOCATION_EXTRA) and (not c:IsType(TYPE_SYNCHRO) or not c:IsRace(RACE_DRAGON))
end

--① 덱/묘지에서 "드래고니아" 카드 서치
function s.thfilter(c)
    return c:IsSetCard(0xc05) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--② 코스트 (제약만 부여)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,3)) -- ⚠ strings.conf 별도
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

--② 조건: 자신 필드에 "드래고니아" 싱크로 몬스터 존재
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xc05) and c:IsType(TYPE_SYNCHRO)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
            -- ✅ ② 효과로 특소된 것을 기록
            c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
        end
    end
end

--③ 조건: ② 효과로 특소되었을 경우
function s.tncon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():HasFlagEffect(128810102)
end
function s.tnop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsFaceup() and c:IsRelateToEffect(e) then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetCode(EFFECT_ADD_TYPE)
        e1:SetValue(TYPE_TUNER)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        c:RegisterEffect(e1)
    end
end
