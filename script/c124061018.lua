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
	e4:SetTarget(aux.TargetBoolFunction(Card.IsArchetype,ARCHETYPE_SPIRITUAL_ART))
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
	c:RegisterEffect(e6)
end
s.listed_series={ARCHETYPE_SPIRITUAL_ART}
--Add attribute
function s.attval(e,c)
	return Duel.GetMatchingGroup(Card.IsArchetype,e:GetHandlerPlayer(),LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,nil,ARCHETYPE_SPIRITUAL_ART):GetBitwiseOr(Card.GetOriginalAttribute)
end
--Activate from Deck
function s.acttg(e,c)
	return c:IsArchetype(ARCHETYPE_SPIRITUAL_ART) and c:IsSpellTrap() and not c:IsFieldSpell()
end
