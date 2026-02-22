-- 환홍마검 플람베르
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 덱에서 줄투르크 특수 소환 (또는 3장 덤핑)
    -- 턴 제약 없음
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 세트 턴 발동 권한 (맬리스 방식)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
    e2:SetValue(function(e) e:SetLabel(1) end)
    e2:SetCondition(function(e) return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_HAND|LOCATION_GRAVE,0,1,e:GetHandler()) end)
    c:RegisterEffect(e2)
    e1:SetLabelObject(e2)

    -- ②: 제외되거나 효과로 묘지에 보내졌을 경우 (HOPT 적용)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.spcon2)
    e3:SetTarget(s.sptg2)
    e3:SetOperation(s.spop2)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_REMOVE)
    e4:SetCondition(s.spcon_rm2)
    c:RegisterEffect(e4)
end

-- "환홍" 카드군 코드 및 줄투르크 코드
s.set_phanred=0xfa8
s.code_surtur=124121127

-- [발동 코스트 필터]
function s.cfilter(c)
    return c:IsType(TYPE_SPELL|TYPE_TRAP) and c:IsAbleToRemoveAsCost()
end

-- [① 발동 코스트] (맬리스 방식)
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

-- [① 줄투르크 특수 소환 필터]
function s.spfilter1(c,e,tp)
    return c:IsCode(s.code_surtur) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- [① 타겟 처리 (토이 솔저 구조 적용)]
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    -- 토이 솔저의 hasbox처럼 hassurtur 변수로 필드 존재 여부 확인 (마함존 취급 등도 고려해 LOCATION_ONFIELD 사용)
    local hassurtur = Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,s.code_surtur),tp,LOCATION_ONFIELD,0,1,nil)
    
    local b1 = Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK,0,1,nil,e,tp)
    local b2 = hassurtur and Duel.IsPlayerCanDiscardDeck(tp,3)
    
    if chk==0 then return b1 or b2 end
    
    if b1 then
        Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
    end
    if b2 then
        Duel.SetPossibleOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,3)
    end
end

-- [① 오퍼레이션 처리]
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local hassurtur = Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,s.code_surtur),tp,LOCATION_ONFIELD,0,1,nil)
    
    local b1 = Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK,0,1,nil,e,tp)
    local b2 = hassurtur and Duel.IsPlayerCanDiscardDeck(tp,3)
    
    if not (b1 or b2) then return end
    
    -- 두 가지 모두 가능할 때 사용자에게 대신 덤핑할지 질문
    if b1 and b2 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        b1 = false -- 덤핑을 선택했으므로 특수 소환은 취소
    elseif b2 and not b1 then
        -- 덤핑만 가능할 경우 그대로 진행
    else
        b2 = false -- 특수 소환을 선택했거나, 애초에 특수 소환만 가능한 경우
    end
    
    -- 최종 결정된 효과 실행
    if b1 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    elseif b2 then
        Duel.DiscardDeck(tp,3,REASON_EFFECT)
    end
end

-- [② 조건] 효과로 묘지행
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

-- [② 조건] 제외됨
function s.spcon_rm2(e,tp,eg,ep,ev,re,r,rp)
    return true
end

-- [② 특수 소환 필터] "환홍"(0xfa8) 몬스터
function s.spfilter2(c,e,tp)
    return c:IsSetCard(s.set_phanred) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
end

-- [② 덱 바운스 필터] 묘지의 함정 카드 전부
function s.tdfilter(c)
    return c:IsType(TYPE_TRAP) and c:IsAbleToDeck()
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
        local tg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.tdfilter),tp,LOCATION_GRAVE,0,nil)
        -- 3번 스트링: "묘지의 함정 카드를 전부 덱으로 되돌리겠습니까?"
        if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.BreakEffect()
            Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end