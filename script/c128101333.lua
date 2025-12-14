local s,id=GetID()
function s.initial_effect(c)
    -------------------------------------------------------------
    -- ① 일반 / 특수 소환 성공시 : 자신 1장 + 상대 2장 제외
    -------------------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.rmtg1)
    e1:SetOperation(s.rmop1)
    c:RegisterEffect(e1)
    local e1b=e1:Clone()
    e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e1b)

    -------------------------------------------------------------
    -- 글로벌 체크 : 레벨 7 메타파이즈 특소 여부 기록
    -------------------------------------------------------------
    if not s.global_check then
        s.global_check=true
        local ge=Effect.GlobalEffect()
        ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge:SetCode(EVENT_SPSUMMON_SUCCESS)
        ge:SetOperation(s.checkop)
        Duel.RegisterEffect(ge,0)
    end

    -------------------------------------------------------------
    -- ② 이 카드가 제외되었을 경우 : 덱에서 "메타파이즈" 제외  
    -- ※ 이 턴에 레벨 7 메타파이즈가 특소된 경우 → 대신 2장
    -------------------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_REMOVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.rmtg2)
    e2:SetOperation(s.rmop2)
    c:RegisterEffect(e2)

    -------------------------------------------------------------
    -- ③ 제외 상태 + 카드가 제외되었을 경우 :
    --    제외된 “메타파이즈” 몬스터 1장 특수 소환
    -------------------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_REMOVE)
    e3:SetRange(LOCATION_REMOVED)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.spcon3)
    e3:SetTarget(s.sptg3)
    e3:SetOperation(s.spop3)
    c:RegisterEffect(e3)
end

-------------------------------------------------------------
-- ① 자신 1장 + 상대 2장 제외
-------------------------------------------------------------
function s.rmtg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,0,1,nil)
           and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,2,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,3,tp,LOCATION_ONFIELD)
end
function s.rmop1(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g1=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,0,1,1,nil)
    if #g1==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g2=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,2,2,nil)
    if #g2<2 then return end
    g1:Merge(g2)
    Duel.Remove(g1,POS_FACEUP,REASON_EFFECT)
end

-------------------------------------------------------------
-- 글로벌 체크 : "레벨 7 메타파이즈" 특소 여부 기록
-------------------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    if eg:IsExists(function(c)
        return c:IsSetCard(0x105) and c:IsLevel(7)
    end,1,nil) then
        Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    end
end

-------------------------------------------------------------
-- ② 제외되었을 때 : 덱에서 메타파이즈 제외(기본 1장, 조건부 2장)
-------------------------------------------------------------
function s.rmfilter(c)
    return c:IsSetCard(0x105) and c:IsAbleToRemove()
end

function s.rmtg2(e,tp,eg,ep,ev,re,r,rp,chk)
    local count = Duel.GetFlagEffect(tp,id)>0 and 2 or 1
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_DECK,0,count,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,count,tp,LOCATION_DECK)
end
function s.rmop2(e,tp,eg,ep,ev,re,r,rp)
    local count = Duel.GetFlagEffect(tp,id)>0 and 2 or 1
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_DECK,0,count,count,nil)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    end
end

-------------------------------------------------------------
-- ③ 제외 상태 + 카드가 제외됨 트리거
-------------------------------------------------------------
function s.spfilter3(c,e,tp)
    return c:IsSetCard(0x105)
        and c:IsMonster()
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
    return not eg:IsContains(e:GetHandler())
end

function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_REMOVED)
            and chkc:IsControler(tp)
            and s.spfilter3(chkc,e,tp)
    end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(s.spfilter3,tp,LOCATION_REMOVED,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter3,tp,LOCATION_REMOVED,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,tp,0)
end

function s.spop3(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    end
end
