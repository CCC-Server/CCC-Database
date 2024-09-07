--闇霊術－「星」
--암령술-"성"
Duel.LoadScript("archetype_crowel.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Set
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
--Set
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,Card.IsAttribute,1,false,nil,nil,ATTRIBUTE_DARK) end
	local g=Duel.SelectReleaseGroupCost(tp,Card.IsAttribute,1,1,false,nil,nil,ATTRIBUTE_DARK)
	Duel.Release(g,REASON_COST)
end
function s.setfilter(c)
	return c:IsArchetype(ARCHETYPE_SPIRITUAL_ART) and (c:IsQuickPlaySpell() or c:IsTrap()) and c:IsSSetable()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return false end
		local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
		return aux.SelectUnselectGroup(g,e,tp,2,2,aux.dncheck,0)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return false end
	local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
	local tg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.dncheck,1,tp,HINTMSG_TOFIELD)
	if #tg~=2 or Duel.SSet(tp,tg)==0 then return end
	local sg=tg:Filter(Card.IsLocation,nil,LOCATION_SZONE)
	for tc in aux.Next(tg) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		if tc:IsTrap() then
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		else	
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		end
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end
