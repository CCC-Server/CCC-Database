-- A・O・J 인필트레이터 셰이드
local s,id=GetID()
function s.initial_effect(c)
    -- ① 패에서 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)

    -- ② 특수 소환 성공 시 상대 묘지 몬스터를 전부 빛 속성으로 변경
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetOperation(s.attrchange)
    c:RegisterEffect(e2)

    -- ③ 퀵 싱크로: 이 카드 + 필드 몬스터로 기계족 싱크로 몬스터 소환
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTarget(s.syntg)
    e3:SetOperation(s.synop)
    c:RegisterEffect(e3)
end
s.listed_series={SET_ALLY_OF_JUSTICE}

-- ■ ①: 자신 필드에 A.O.J 몬스터 2장 이상 있을 경우 패에서 특수 소환
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,SET_ALLY_OF_JUSTICE)>=2
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ■ ②: 특수 소환 성공 시 상대 묘지 몬스터 속성을 빛으로 변경
function s.attrchange(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsLocation,tp,0,LOCATION_GRAVE,nil)
    for tc in g:Iter() do
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
        e1:SetValue(ATTRIBUTE_LIGHT)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
        tc:RegisterEffect(e1)
    end
end

-- ■ ③: 퀵 싱크로 (이 카드 + 필드 몬스터 → 기계족 싱크로 소환)
function s.synfilter(sc,c,tp)
    local g=Group.FromCards(c,sc)
    return sc:IsRace(RACE_MACHINE)
        and Duel.GetLocationCountFromEx(tp,tp,g,sc)>0
        and sc:IsSynchroSummonable(nil,g)
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local c=e:GetHandler()
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and chkc~=c end
    if chk==0 then
        return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_MZONE,0,1,c)
            and Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,c,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,c)
end
function s.synop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not c:IsRelateToEffect(e) or not tc or not tc:IsRelateToEffect(e) then return end
    local g=Group.FromCards(c,tc)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,function(sc)
        return sc:IsRace(RACE_MACHINE)
            and Duel.GetLocationCountFromEx(tp,tp,g,sc)>0
            and sc:IsSynchroSummonable(nil,g)
    end,tp,LOCATION_EXTRA,0,1,1,nil)
    local sc=sg:GetFirst()
    if sc then
        Duel.SynchroSummon(tp,sc,nil,g)
    end
end
