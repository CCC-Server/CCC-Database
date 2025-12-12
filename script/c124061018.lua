--大霊術－「一流」
--대령술－「일류」
Duel.LoadScript("archetype_crowel.lua")
Duel.LoadScript("newEffect_ActInRange.lua")	--EFFECT_ACT_IN_RANGE
local s,id=GetID()
function s.initial_effect(c)
	newEffect.ActInRange.EnableCheck()
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Add attribute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetTarget(aux.TargetBoolFunction(function(c) return c:IsMonster() and (c:IsFaceup() or not c:IsLocation(LOCATION_ONFIELD)) end))
	e2:SetCode(EFFECT_ADD_ATTRIBUTE)
	e2:SetValue(s.attval)
	c:RegisterEffect(e2)
	--Activate from Hand
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_HAND,0)
	e4:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,ARCHETYPE_SPIRITUAL_ART))
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e5)
	--Activate from Deck
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_ACT_IN_RANGE)
	e6:SetRange(LOCATION_FZONE)
	e6:SetTargetRange(LOCATION_DECK,0)
	e6:SetTarget(s.acttg)
	e6:SetValue(s.actop)
	c:RegisterEffect(e6)
	--Inactivatable
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_CANNOT_INACTIVATE)
	e7:SetRange(LOCATION_FZONE)
	e7:SetValue(s.efffilter)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e8)
end
s.listed_series={ARCHETYPE_SPIRITUAL_ART}
--Add attribute
function s.attval(e,c)
	return Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,ARCHETYPE_SPIRITUAL_ART),e:GetHandlerPlayer(),LOCATION_MZONE+LOCATION_GRAVE,0,nil):GetBitwiseOr(Card.GetOriginalAttribute)
end
--Activate from Deck
function s.costfilter1(c,tc,e)
	if not c:IsAbleToDeckAsCost() then return false end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(1)
	e1:SetReset(RESET_CHAIN)
	c:RegisterEffect(e1,true)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_USE_AS_COST)
	c:RegisterEffect(e2,true)
	local te=tc:GetActivateEffect()
	local res=te and te:IsActivatable(e:GetHandlerPlayer(),true,false)
	e2:Reset()
	e1:Reset()
	return res
end
function s.costfilter2(c,te,e)
	if not c:IsAbleToDeckAsCost() then return false end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(1)
	e1:SetReset(RESET_CHAIN)
	c:RegisterEffect(e1,true)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_USE_AS_COST)
	c:RegisterEffect(e2,true)
	local cost=te:GetCost()
	local tg=te:GetTarget()
	local eg,ep,ev,re,r,rp=Duel.GetChainInfo(Duel.GetCurrentChain())
	local res=(not cost or cost(te,te:GetHandlerPlayer(),eg,ep,ev,re,r,rp,0))
			and (not tg or tg(te,te:GetHandlerPlayer(),eg,ep,ev,re,r,rp,0))
	e2:Reset()
	e1:Reset()
	return res
end
function s.acttg(e,c)
	return c:IsSetCard(ARCHETYPE_SPIRITUAL_ART) and (c:IsQuickPlaySpell() or c:IsTrap())
		and (not c:IsLocation(LOCATION_DECK) or Duel.IsExistingMatchingCard(s.costfilter1,e:GetHandlerPlayer(),LOCATION_HAND,0,1,nil,c,e))
end
function s.actop(e,te,tp)
	--Duel.Hint(HINT_CARD,0,id)
	Duel.HintSelection(e:GetHandler(),true)

	local ep=te:GetHandlerPlayer()
	Duel.Hint(HINT_SELECTMSG,ep,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(ep,s.costfilter2,ep,LOCATION_HAND,0,1,1,nil,te,e)
	Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_COST)
end
function s.efffilter(e,ct)
	local p=e:GetHandler():GetControler()
	local te,tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	return p==tp and te:GetHandler():IsSetCard(ARCHETYPE_SPIRITUAL_ART)
		and (te:IsMonsterEffect() or (te:IsSpellTrapEffect() and te:IsHasType(EFFECT_TYPE_ACTIVATE)))
end
