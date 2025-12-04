--FATALITY
local s,id=GetID()
function c128220092.initial_effect(c)
    --Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
    --Can be activated the turn it was Set
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCondition(s.actcon)
	c:RegisterEffect(e2)
end
function s.lkfilter(c,e,tp)
	return c:IsFaceup()
end
function s.ctrlfilter(c,tp,sc)
	return  c:IsFaceup() 
end
function s.spfilter(c,e,tp,sc)
	return c:IsFaceup() and c:IsControler(1-tp) and c:IsLocation(LOCATION_MZONE) and c:IsAbleToRemove(tp,POS_FACEDOWN,REASON_EFFECT) and c:GetAttack()==0
end
	function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local b1=Duel.IsExistingTarget(s.ctrlfilter,tp,0,LOCATION_MZONE,1,nil)
	local b2=Duel.IsExistingTarget(s.spfilter,tp,0,LOCATION_MZONE,1,nil,e,tp,c)
	if chkc then
		local label=e:GetLabel()
		if label==1 then
			return chkc:IsLocation(LOCATION_MZONE)  and chkc:IsControler(1-tp) and s.ctrlfilter(chkc,tp,c)
		elseif label==2 then
			return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.spfilter(chkc,tp,c)
	end
	end
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)},
		{b2,aux.Stringid(id,2)})
	e:SetLabel(op)
	if op==1 then
	    target_filter = s.ctrlfilter
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND+CATEGORY_SEARCH,tc,1,0,0)
	elseif op==2 then
	    target_filter = s.spfilter
		e:SetCategory(CATEGORY_REMOVE)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,0,0)
		end
	local g = Duel.SelectTarget(tp,target_filter,tp,0,LOCATION_MZONE,1,1,nil,e,tp,c)
	end
function s.ttgfilter(c)
	return c:IsMonster() and c:IsSetCard(0xc24) and not c:IsCode(id)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
		local op=e:GetLabel()
	    if op==1 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(2000)
		tc:RegisterEffect(e1)
		if Duel.GetMatchingGroup(s.ttgfilter,tp,LOCATION_DECK,0,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.ttgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g==0 then return end
	    Duel.BreakEffect()
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		end
	elseif op==2 then
	Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	end
		end
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroupCount(s.disfilter,tp,0,LOCATION_MZONE,nil)
	return g>0
end
function s.disfilter(c)
	return c:IsFaceup() and c:GetAttack()~=c:GetBaseAttack()
end
