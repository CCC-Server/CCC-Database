--포레드런 가디언 트리
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --cannot special summon
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(aux.FALSE)
    c:RegisterEffect(e1)
    --special summon
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e2:SetCondition(s.spcon)
    c:RegisterEffect(e2)
    --immune
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.immtg)
    e3:SetCondition(s.econ)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)
    --Special summon 1 rank 3 or lower Xyz monster from extra deck
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id)
    e4:SetCondition(s.spcon2)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

function s.spfilter(c)
    return c:IsSetCard(0x81d) and c:IsFaceup()
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>-3
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,3,nil)
end

function s.ecfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x81d) and c:IsLevel(3)
end

function s.econ(e)
    return Duel.IsExistingMatchingCard(s.ecfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.immtg(e,c)
    return c~=e:GetHandler() and c:IsSetCard(0x81d) and c:IsLevel(3)
end

function s.efilter(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActiveType(TYPE_MONSTER)
        and (te:IsLevelAbove(5) or te:IsRankAbove(5) or te:IsLinkAbove(3))
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.efilter,tp,0,LOCATION_MZONE,1,nil)
end

function s.filter(c,e,tp)
    return c:IsSetCard(0x81d) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP) end
end