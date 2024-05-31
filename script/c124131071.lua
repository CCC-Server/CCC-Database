--이블 히어로 와일드 크러셔
local s,id=GetID()
function s.initial_effect(c)
--Change its name to "엘리멘틀 히어로 와일드맨"
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
e1:SetCode(EFFECT_CHANGE_CODE)
e1:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE)
e1:SetValue(86188410)
c:RegisterEffect(e1)
--Provide effect when used as material
local e3=Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
e3:SetCode(EVENT_BE_MATERIAL)
e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
e3:SetCondition(s.efcon)
e3:SetOperation(s.efop)
c:RegisterEffect(e3)
end
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
local p=e:GetHandler()
return (r&REASON_FUSION)~=0 and p:GetReasonCard():IsSetCard(0x6008)
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
local c=e:GetHandler()
local rc=c:GetReasonCard()
--register the effect
--destroy
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,1))
e3:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
e3:SetType(EFFECT_TYPE_IGNITION)
e3:SetRange(LOCATION_MZONE)
e3:SetCountLimit(1)
e3:SetTarget(s.destg)
e3:SetOperation(s.desop)
e3:SetReset(RESET_EVENT+RESETS_STANDARD)
rc:RegisterEffect(e3,true)
--register the hint
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,0))
e2:SetType(EFFECT_TYPE_SINGLE)
e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
e2:SetReset(RESET_EVENT+RESETS_STANDARD)
rc:RegisterEffect(e2,true)
--in case the monster did not have an effect
if not rc:IsType(TYPE_EFFECT) then
local e4=Effect.CreateEffect(c)
e4:SetType(EFFECT_TYPE_SINGLE)
e4:SetCode(EFFECT_ADD_TYPE)
e4:SetValue(TYPE_EFFECT)
e4:SetReset(RESET_EVENT+RESETS_STANDARD)
rc:RegisterEffect(e4,true)
end
end
function s.dfilter(c,atk)
return c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
local g=Duel.GetMatchingGroup(s.dfilter,tp,0,LOCATION_ONFIELD,nil)
if chk==0 then return #g>0 end
Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*200)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
local g=Duel.GetMatchingGroup(s.dfilter,tp,0,LOCATION_ONFIELD,nil)
local ct=Duel.Destroy(g,REASON_EFFECT)
Duel.Damage(1-tp,ct*200,REASON_EFFECT)
end