--플라이어 데이지
local s,id=GetID()
function s.initial_effect(c)

    --Special Summon 2 "Flyer Tokens" when used as Link Material
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_BE_MATERIAL)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

s.listed_names={124131056} --Flyer Token
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_LINK
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>1
        and Duel.IsPlayerCanSpecialSummonMonster(tp,124131056,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK) end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    for i=1,2 do
        local token=Duel.CreateToken(tp,124131056)
        Duel.SpecialSummonStep(token,0,tp,1-tp,false,false,POS_FACEUP)
    end
    Duel.SpecialSummonComplete()
end