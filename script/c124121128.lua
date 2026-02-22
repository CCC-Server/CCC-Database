-- 환홍마검 레바테인
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 카드 발동 (덱/묘지 세트)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 세트 턴 발동 권한 (맬리스 방식)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
    e2:SetValue(function(e) e:SetLabel(1) end)
    e2:SetCondition(function(e) return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_HAND|LOCATION_GRAVE,0,1,e:GetHandler()) end)
    c:RegisterEffect(e2)
    e1:SetLabelObject(e2)

    -- ②: 제외되거나 효과로 묘지에 보내졌을 경우
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_REMOVE)
    e4:SetCondition(s.spcon_rm)
    c:RegisterEffect(e4)
end

-- [발동 코스트 필터] 마법/함정 카드 제외
function s.cfilter(c)
    return c:IsType(TYPE_SPELL|TYPE_TRAP) and c:IsAbleToRemoveAsCost()
end

-- [① 발동 코스트] 맬리스 방식 적용
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local label_obj=e:GetLabelObject()
    if chk==0 then 
        label_obj:SetLabel(0) 
        return true 
    end
    if label_obj:GetLabel()>0 then
        label_obj:SetLabel(0)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,e:GetHandler())
        Duel.Remove(g,POS_FACEUP,REASON_COST)
    end
end

-- [① 세트 대상 필터] "환홍마검 레바테인" 이외의 "환홍"(0xfa8) 함정 카드
function s.setfilter(c)
    return c:IsSetCard(0xfa8) and c:IsType(TYPE_TRAP) and not c:IsCode(id) and c:IsSSetable()
end

-- [① 발동 타겟]
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) end
end

-- [① 발동 효과 처리]
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sc=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil):GetFirst()
    if sc and Duel.SSet(tp,sc)>0 then
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(aux.Stringid(id,4)) -- "세트한 턴에도 발동할 수 있다" 스트링
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetReset(RESET_EVENT|RESETS_STANDARD)
        sc:RegisterEffect(e1)
    end
end

-- [② 조건] 효과로 묘지행
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

-- [② 조건] 제외됨
function s.spcon_rm(e,tp,eg,ep,ev,re,r,rp)
    return true
end

-- [② 특수 소환 필터] "환홍"(0xfa8) 몬스터
function s.spfilter(c,e,tp)
    return c:IsSetCard(0xfa8) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
end

-- [② 덱 바운스 필터] 묘지의 함정 카드 전부
function s.tdfilter(c)
    return c:IsType(TYPE_TRAP) and c:IsAbleToDeck()
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
        local tg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.tdfilter),tp,LOCATION_GRAVE,0,nil)
        if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.BreakEffect()
            Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end