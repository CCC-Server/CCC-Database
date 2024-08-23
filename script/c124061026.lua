--大霊術－「一路」
--대령술－「일로」
Duel.LoadScript("archetype_crowel.lua")
Duel.LoadScript("newEffect_ActInRange.lua")	--EFFECT_ACT_IN_RANGE
local s,id=GetID()
function s.initial_effect(c)
	newEffect.ActInRange.EnableCheck()
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
	--Activate from Deck/GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_ACT_IN_RANGE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_DECK,0)
	e2:SetTarget(s.acttg)
	e2:SetCondition(newEffect.ActInRange.LimitCon())
	e2:SetValue(newEffect.ActInRange.LimitOp())
	e2:SetCountLimit(1,{id,1})
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetTargetRange(LOCATION_GRAVE,0)
	c:RegisterEffect(e3)
	--Redirect

	--Activate self from Banished
	
end
s.listed_series={ARCHETYPE_SPIRITUAL_ART}
--Activate from Deck/GY
function s.acttg(e,c)
	return c:IsArchetype(ARCHETYPE_SPIRITUAL_ART) and not c:IsCode(id) and c:IsFieldSpell()
end
