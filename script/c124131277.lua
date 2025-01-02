--플라이어 라벤더
local s,id=GetID()
function s.initial_effect(c)
    --Link Summon method
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,2,2)
    --Cannot be targeted
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e1:SetCondition(s.e1con)
    e1:SetTarget(s.e1target)
    e1:SetValue(aux.tgoval)
    c:RegisterEffect(e1)
    --Special Summon from GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.e2target)
    e2:SetOperation(s.e2operation)
    c:RegisterEffect(e2)
end

function s.matfilter(c,lc,stype,tp)
    return c:IsRace(RACE_PLANT,lc,stype,tp)
end

function s.e1con(e)
    return Duel.IsExistingMatchingCard(s.gardenfilter,e:GetHandlerPlayer(),LOCATION_FZONE,0,1,nil)
end

function s.gardenfilter(c)
    return c:IsOriginalCode(71645242) or c:IsOriginalCode(124131054)
end

function s.e1target(e,c)
    return c:IsRace(RACE_PLANT)
end

function s.e2target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGraveAsCost,tp,0,LOCATION_MZONE,1,nil)
        and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(Card.IsRace),tp,LOCATION_GRAVE,0,1,nil,RACE_PLANT) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGraveAsCost,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.Release(g,REASON_COST)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.e2operation(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsRace),tp,LOCATION_GRAVE,0,1,1,nil,RACE_PLANT)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end