--괴이물 세계 증명
Duel.LoadScript("strings.lua")
local s,id=GetID()
function s.initial_effect(c)
	--effect 1
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xff0) 
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	rc=re:GetHandler()
	return rp==1-tp and Duel.IsChainNegatable(ev) and not (rc:IsSetCard(0xff0) and rc:IsMonster()) and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
		Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,eg,1,1-tp,LOCATION_ALL)
	end
end

function s.act1filter(c)
	return c:IsFaceup() and c:IsSetCard(0xff0) and c:IsRace(RACE_WARRIOR)
end

function s.act2filter(c)
	return c:IsFaceup() and c:IsSetCard(0xff0) and c:IsRace(RACE_BEASTWARRIOR)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local k=0
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		if Duel.IsExistingMatchingCard(s.act1filter,tp,LOCATION_MZONE,0,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			k=Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
		else 
			k=Duel.Destroy(eg,REASON_EFFECT) 
		end
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil,e,tp)
		if k~=0 and Duel.IsExistingMatchingCard(s.act2filter,tp,0,LOCATION_MZONE,1,nil) and #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_DESTROY):GetFirst()
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end