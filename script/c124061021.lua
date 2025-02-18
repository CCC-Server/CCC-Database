--空霊術－「　」
--공령술-「　」
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.filter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsAttribute(ATTRIBUTE_DARK) 
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,s.filter,1,false,nil,nil) end
	local g=Duel.SelectReleaseGroupCost(tp,s.filter,1,1,false,nil,nil)
	Duel.Release(g,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_EXTRA,LOCATION_EXTRA)>0 and Duel.IsPlayerCanRemove(tp) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.GetFieldGroupCount(tp,LOCATION_EXTRA,0)>0
	local b2=Duel.GetFieldGroupCount(tp,0,LOCATION_EXTRA)>0
	local g=nil
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)})
	if op==1 then
		g=Duel.GetFieldGroup(tp,LOCATION_EXTRA,0)
	else
		g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
	end
	if #g<1 then return end
	Duel.ConfirmCards(tp,g)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=g:FilterSelect(tp,Card.IsAbleToRemove,1,1,nil,tp,POS_FACEUP)
	if #sg>0 then
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
	Duel.ShuffleExtra(1-tp)
end
