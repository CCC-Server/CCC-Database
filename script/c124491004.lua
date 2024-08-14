--뱀파이어 쏜
local s,id=GetID()
function s.initial_effect(c)
--Activate
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetCountLimit(1,id) 
e1:SetCost(s.tkncost)
e1:SetTarget(s.tkntarget)
e1:SetOperation(s.activate)
c:RegisterEffect(e1)
--destroy
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,0))
e2:SetCategory(CATEGORY_DESTROY)
e2:SetType(EFFECT_TYPE_IGNITION)
e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
e2:SetRange(LOCATION_GRAVE)
e2:SetCountLimit(1,id)
e2:SetCost(aux.bfgcost)
e2:SetTarget(s.destg)
e2:SetOperation(s.desop)
c:RegisterEffect(e2)
end
s.listed_names={124491010}
function s.tknfilter(c)
return c:IsRace(RACE_ZOMBIE) and c:IsLevelAbove(5) and not c:IsPublic()
end
function s.tkncost(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return Duel.IsExistingMatchingCard(s.tknfilter,tp,LOCATION_HAND,0,1,nil) end
Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
local g=Duel.SelectMatchingCard(tp,s.tknfilter,tp,LOCATION_HAND,0,1,1,nil)
Duel.ConfirmCards(1-tp,g)
Duel.ShuffleHand(tp)
end
function s.tkntarget(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) and Duel.GetLocationCount(tp,LOCATION_MZONE)>1 
and Duel.IsPlayerCanSpecialSummonMonster(tp,id+6,SET_VAMPIRE,TYPES_TOKEN,0,0,1,RACE_ZOMBIE,ATTRIBUTE_DARK) end
Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end
function s.sumfilter(c)
return c:IsRace(RACE_ZOMBIE) and c:IsLevelAbove(5) and c:IsSummonable(true,nil,1)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
if not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
and Duel.IsPlayerCanSpecialSummonMonster(tp,id+6,SET_VAMPIRE,TYPES_TOKEN,0,0,1,RACE_ZOMBIE,ATTRIBUTE_DARK) then
for i=1,2 do
local token=Duel.CreateToken(tp,id+6)
Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
end
Duel.SpecialSummonComplete()
local g=Duel.GetMatchingGroup(s.sumfilter,tp,LOCATION_HAND,0,nil)
if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
Duel.BreakEffect()
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
local sc=g:Select(tp,1,1,nil):GetFirst()
Duel.ShuffleHand(tp)
Duel.Summon(tp,sc,true,nil,1)
else
Duel.ShuffleHand(tp)
end
end
end
function s.descond(c)
return c:IsFaceup() and c:IsSetCard(SET_VAMPIRE) and c:IsAttackAbove(2000)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() end
if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
local fc=Duel.IsExistingMatchingCard(s.descond,tp,LOCATION_MZONE,0,1,nil)
local ct=1
if fc then ct=2 end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,ct,nil)
Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
local g=Duel.GetTargetCards(e)
if #g>0 then
Duel.Destroy(g,REASON_EFFECT)
end
end