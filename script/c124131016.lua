--리퍼
local s,id=GetID()
function s.initial_effect(c)
	c:EnableUnsummonable()
	c:SetUniqueOnField(1,0,id)
	--spsummon condition
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE)
	c:RegisterEffect(e0)
	 --special summon
 	local e2=Effect.CreateEffect(c)
 	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
 	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
 	e2:SetRange(LOCATION_HAND)
 	e2:SetCondition(s.spcon)
 	e2:SetOperation(s.spop)
 	c:RegisterEffect(e2)
	--Can attack all monsters
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_ATTACK_ALL)
	e3:SetValue(1)
	c:RegisterEffect(e3)
 	--banish
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCost(s.rmcost)
	e4:SetTarget(s.rmtg)
	e4:SetOperation(s.rmop)
	c:RegisterEffect(e4)
end
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsSetCard(0x810)
		and (se:IsHasType(EFFECT_TYPE_ACTIONS) or se:GetCode()==EFFECT_SPSUMMON_PROC)
end
function s.spfilter(c,code)
 return c:GetCode()==code
end
function s.spcon(e,c)
 if c==nil then return true end
 local tp=c:GetControler()
 return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
  and Duel.CheckReleaseGroup(tp,s.spfilter,1,nil,124131014)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
 local g1=Duel.SelectReleaseGroup(tp,s.spfilter,1,1,nil,124131014)
 Duel.Release(g1,REASON_COST)
end
function s.cfilter(c)
	return c:IsSetCard(0x810) and c:IsAbleToRemoveAsCost()
end
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end