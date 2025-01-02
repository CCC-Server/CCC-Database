--플라이어 로즈마리
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --Special Summon "Flyer Token"
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.tokencost)
    e2:SetTarget(s.tokentg)
    e2:SetOperation(s.tokenop)
    c:RegisterEffect(e2)

--Graveyard effect negate
local e7=Effect.CreateEffect(c)
e7:SetType(EFFECT_TYPE_FIELD)
e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
e7:SetCode(EFFECT_CANNOT_ACTIVATE)
e7:SetRange(LOCATION_MZONE)
e7:SetTargetRange(0,LOCATION_GRAVE)
e7:SetCondition(s.negcon)
e7:SetValue(s.val2)
c:RegisterEffect(e7)
    
end

s.listed_names={124131056} --Flyer Token

function s.spcfilter(c,tp)
    return c:IsRace(RACE_PLANT) and (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or (c:IsLocation(LOCATION_MZONE) and c:GetSequence()<5))
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spcfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=Duel.SelectMatchingCard(tp,s.spcfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp)
    Duel.Release(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

function s.spcfilter2(c,tp)
    return c:IsRace(RACE_PLANT)
end

function s.tokencost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spcfilter2,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.spcfilter2,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,124131056,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK) end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<1 or not Duel.IsPlayerCanSpecialSummonMonster(tp,124131056,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK) then return end
    local token=Duel.CreateToken(tp,124131056)
    Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP)
end

function s.negcon(e)
    return Duel.IsExistingMatchingCard(Card.IsType,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,TYPE_TOKEN) and Duel.IsExistingMatchingCard(Card.IsOriginalRace,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,RACE_PLANT)
end
function s.val2(e,re,tp)
	return re:GetActivateLocation()==LOCATION_GRAVE 
end
