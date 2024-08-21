--大霊術－「一流」
--대령술－「일류」
Duel.LoadScript("archetype_crowel.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Add attribute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE+LOCATION_GRAVE,0)
	e2:SetTarget(aux.TargetBoolFunction(function(c) return c:IsMonster() and (c:IsFaceup() or not c:IsLocation(LOCATION_ONFIELD)) end))
	e2:SetCode(EFFECT_ADD_ATTRIBUTE)
	e2:SetValue(s.attval1)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetTargetRange(0,LOCATION_MZONE+LOCATION_GRAVE)
	e3:SetValue(s.attval2)
	c:RegisterEffect(e3)
	--Activate from Hand
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_HAND,0)
	e4:SetTarget(aux.TargetBoolFunction(Card.IsArchetype,ARCHETYPE_SPIRITUAL_ART))
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e5)
	--Global Effects to handle rules
	aux.GlobalCheck(s,function()
		--Cannot cost itself
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD)
		ge1:SetCode(EFFECT_CANNOT_USE_AS_COST)
		ge1:SetProperty(EFFECT_FLAG_IGNORE_RANGE)
		ge1:SetTarget(function(e,c)
			local te=e:GetLabelObject()
			return te and te:GetHandler()==c
		end)
		ge1:SetLabelObject(nil)
		Duel.RegisterEffect(ge1,0)
		s.Setge1LabelObject=(function(e) ge1:SetLabelObject(e) end)
		--Move to field
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD)
		ge2:SetCode(EFFECT_ACTIVATE_COST)
		ge2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		ge2:SetTargetRange(1,1)
		ge2:SetTarget(s.actarget)
		ge2:SetCost(s.acchk)
		ge2:SetOperation(s.acop)
		Duel.RegisterEffect(ge2,0)
		s.SetLabelObjectge2=(function(e) e:SetLabelObject(ge2) end)
	end)
	s.Setge1LabelObject(nil)
	--Activate from Deck
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,4))
	e6:SetType(EFFECT_TYPE_ACTIVATE)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_DECK)
	e6:SetCondition(s.cpcon)
	e6:SetCost(s.cpcost)
	e6:SetTarget(s.cptg)
	e6:SetOperation(s.cpop)
	s.SetLabelObjectge2(e6)
	--Grant Effect (Should be moved to proc_***.lua)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e7:SetRange(LOCATION_FZONE)
	e7:SetTargetRange(LOCATION_DECK,0)
	e7:SetTarget(s.grtg)
	e7:SetLabelObject(e6)
	c:RegisterEffect(e7)
end
s.listed_series={ARCHETYPE_SPIRITUAL_ART}
s.Setge1LabelObject=nil
s.SetLabelObjectge2=nil
s.apply_con={}
s.apply_cost={}
--Add attribute
function s.mfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)
		and (c:GetBaseAttack()==1850 or (c:GetBaseAttack()==500 and c:GetBaseDefense()==1500))
end
function s.attval1(e,c)
	return Duel.GetMatchingGroup(s.mfilter,e:GetHandlerPlayer(),LOCATION_MZONE+LOCATION_GRAVE,0,nil):GetBitwiseOr(Card.GetOriginalAttribute)
end
function s.attval2(e,c)
	return Duel.GetMatchingGroup(s.mfilter,e:GetHandlerPlayer(),0,LOCATION_MZONE+LOCATION_GRAVE,nil):GetBitwiseOr(Card.GetOriginalAttribute)
end
--Grant Effect
function s.grtg(e,c)
	return c:IsArchetype(ARCHETYPE_SPIRITUAL_ART) and (c:IsQuickPlaySpell() or c:IsTrap())
end
--Activate from Deck
function s.cpcon(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetHandler():GetActivateEffect()
	local con=te:GetCondition()
	if con then return con(e,tp,eg,ep,ev,re,r,rp) end
	return true
end
function s.cpcost(e,tp,eg,ep,ev,re,r,rp,chk)
	s.Setge1LabelObject(e)
	local te=e:GetHandler():GetActivateEffect()
	local co=te:GetCost()
	local result=true
	if chk==0 then
		if co then result=co(e,tp,eg,ep,ev,re,r,rp,0) end
		s.Setge1LabelObject(nil)
		return result
	end
	if co then co(e,tp,eg,ep,ev,re,r,rp,1) end
	s.Setge1LabelObject(nil)
end
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local te=e:GetHandler():GetActivateEffect()
	local tg=te:GetTarget()
	local result=true
	if chkc then
		if tg then result=tg(e,tp,eg,ep,ev,re,r,rp,0,chkc) end
		s.SetLabelObjectge2(e)
		return result
	end
	if chk==0 then
		if tg then result=tg(e,tp,eg,ep,ev,re,r,rp,0) end
		s.SetLabelObjectge2(e)
		return result
	end
	if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetHandler():GetActivateEffect()
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end
--Global Effects to handle rules
function s.actarget(e,te,tp)
	return te:GetLabelObject()==e
end
function s.tdfilter(c,tp)
	return Duel.IsPlayerCanSendtoDeck(tp,c)
end
function s.acchk(e,te,tp)
	--This card's case
	--if te:GetHandler():IsLocation(LOCATION_DECK) and Duel.GetMatchingGroupCount(s.tdfilter,tp,LOCATION_HAND,0,nil,tp)<1 then return false end
	--General cases
	if te:GetHandler():IsForbidden() then return false end
	local category=te:GetActiveType()
	local result=false
	local loc=0
	if category&TYPE_FIELD>0 then
		result=true
	elseif category&TYPE_PENDULUM>0 then
		result=Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
	elseif category&(TYPE_SPELL|TYPE_TRAP)>0 then
		result=Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		--◆ limit zone 관련 추가 코드 필요
	end
	return result
end
function s.acop(e,tp,eg,ep,ev,re,r,rp)
	--This card's case
	Duel.Hint(HINT_CARD,0,id)
	--local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_HAND,0,1,1,nil,tp)
	--Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_RULE)
	--General cases
	--◆ use limit 관련 추가 코드 필요
end