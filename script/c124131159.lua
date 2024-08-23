--동의 천칭
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end
s.listed_series={0x501}
s.listed_names={100000653} -- "연금수-동의 우로보로스" 카드의 코드

function s.spfilter1(c,e,tp)
    return c:IsCode(100000653) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spfilter2(c,e,tp)
    return c:IsSetCard(0x501) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and not c:IsCode(100000653)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>1
        and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
        and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
    local b2=true -- 상대에게 데미지를 주는 효과이므로 항상 가능
    if chk==0 then return b1 or b2 end
    local op=Duel.SelectEffect(tp,
        {b1,aux.Stringid(id,0)},
        {b2,aux.Stringid(id,1)})
    e:SetLabel(op)
    if op==1 then
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK+LOCATION_REMOVED)
    else
        Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()
    if op==1 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
        local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
        local g2=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
        if #g1>0 and #g2>0 then
            Duel.SpecialSummonStep(g1:GetFirst(),0,tp,tp,false,false,POS_FACEUP)
            Duel.SpecialSummonStep(g2:GetFirst(),0,tp,tp,false,false,POS_FACEUP)
            Duel.SpecialSummonComplete()
        end
        -- 엑스트라 덱 특수 소환 제한
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.splimit)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
    elseif op==2 then
        Duel.Damage(1-tp,1000,REASON_EFFECT)
    end
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsLocation(LOCATION_EXTRA)
end