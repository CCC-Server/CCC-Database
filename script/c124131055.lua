--플라이어 릴리
local s,id=GetID()
function s.initial_effect(c)
--Link Summon
c:EnableReviveLimit()
Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_PLANT),2)
--atk change
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
e1:SetRange(LOCATION_MZONE)
e1:SetValue(s.atkval)
c:RegisterEffect(e1)
--disable spsummon
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,0))
e3:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY)
e3:SetType(EFFECT_TYPE_QUICK_O)
e3:SetRange(LOCATION_MZONE)
e3:SetCode(EVENT_SPSUMMON)
e3:SetCountLimit(1,id)
e3:SetCondition(s.condition)
e3:SetTarget(s.target)
e3:SetOperation(s.operation)
c:RegisterEffect(e3)
--식물족이 된다
local e6=Effect.CreateEffect(c)
e6:SetType(EFFECT_TYPE_FIELD)
e6:SetType(EFFECT_TYPE_FIELD)
e6:SetCode(EFFECT_CHANGE_RACE)
e6:SetRange(LOCATION_MZONE)
e6:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
e6:SetCondition(s.tgcon)
e6:SetValue(RACE_PLANT)
c:RegisterEffect(e6)
end
function s.atkval(e,c)
return Duel.GetMatchingGroupCount(Card.IsRace,c:GetControler(),LOCATION_GRAVE,0,nil,RACE_PLANT)*400
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
return tp~=ep and Duel.GetCurrentChain()==0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK,POS_FACEUP_DEFENSE,1-tp) end
Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,#eg,0,0)
Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,#eg,0,0)
Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp,chk)
Duel.NegateSummon(eg)
if Duel.Destroy(eg,REASON_EFFECT) then
Duel.BreakEffect()
if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<1 or not Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,0,0,1,RACE_PLANT,ATTRIBUTE_DARK,POS_FACEUP_DEFENSE,1-tp) then return end
local token=Duel.CreateToken(tp,124131056)
Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE)
end
end
function s.tgcon(e)
	return Duel.IsExistingMatchingCard(Card.IsType,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,TYPE_TOKEN) and Duel.IsExistingMatchingCard(Card.IsRace,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,RACE_PLANT)
end