-- 환홍마검 레바테인
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 카드 발동 (덱에서 2장 골라 1장 세트, 나머지 패로)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
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

-- "환홍" 카드군 코드 (0xfa8)
s.set_phanred=0xfa8

-- [발동 코스트 필터]
function s.cfilter(c)
    return c:IsType(TYPE_SPELL|TYPE_TRAP) and c:IsAbleToRemoveAsCost()
end

-- [① 발동 코스트]
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

-- [① 세트/서치 대상 필터] (킬러튠 참조: 세트 가능하거나 패에 넣을 수 있는 카드)
function s.thsetfilter(c)
    return c:IsSetCard(s.set_phanred) and c:IsType(TYPE_TRAP) and not c:IsCode(id)
        and (c:IsSSetable() or c:IsAbleToHand())
end

-- [① 조합 검증] (고른 2장 중 1장이 세트 가능하고, 나머지 1장이 패에 들어갈 수 있는지)
function s.validselection(c,sg)
    return c:IsSSetable() and sg:IsExists(Card.IsAbleToHand,1,c)
end
function s.rescon(sg,e,tp,mg)
    return sg:IsExists(s.validselection,1,nil,sg)
end

-- [① 발동 타겟]
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.thsetfilter,tp,LOCATION_DECK,0,nil)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and #g>=2
        and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- [① 발동 효과 처리] (킬러튠 리믹스의 그룹 빼기 로직 적용)
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    
    local g=Duel.GetMatchingGroup(s.thsetfilter,tp,LOCATION_DECK,0,nil)
    if #g<2 then return end
    
    -- 덱에서 조건에 맞는 2장을 먼저 고름
    local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_OPERATECARD)
    if #sg<2 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    -- 고른 2장 중에서 세트할 1장을 선택
    local setc=sg:FilterSelect(tp,s.validselection,1,1,nil,sg):GetFirst()
    -- 원래 2장 그룹(sg)에서 세트할 카드(setc)를 빼서 남은 1장을 패에 넣을 카드(thc)로 지정
    local thc=(sg-setc):GetFirst()
    
    -- 세트를 실행하고 성공했다면
    if setc and Duel.SSet(tp,setc)>0 then
        -- 당일 발동 권한 부여
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(aux.Stringid(id,4))
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetReset(RESET_EVENT|RESETS_STANDARD)
        setc:RegisterEffect(e1)
        
        -- 남은 카드를 패로 넣음
        if thc then
            Duel.SendtoHand(thc,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,thc)
        end
    end
end

-- [② 조건]
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

function s.spcon_rm(e,tp,eg,ep,ev,re,r,rp)
    return true
end

-- [② 특수 소환 타겟]
function s.spfilter(c,e,tp)
    return c:IsSetCard(s.set_phanred) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
end

-- [② 덱 바운스 필터]
function s.tdfilter(c)
    return c:IsType(TYPE_TRAP) and c:IsAbleToDeck()
end

-- [② 효과 처리: 특수 소환 후 선택적 바운스]
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