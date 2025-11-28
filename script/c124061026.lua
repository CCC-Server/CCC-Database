--大霊術－「一路」
--대령술－「일로」
Duel.LoadScript("archetype_crowel.lua")
Duel.LoadScript("newEffect_ActInRange.lua") --EFFECT_ACT_IN_RANGE
local s,id=GetID()
function s.initial_effect(c)
	newEffect.ActInRange.EnableCheck()
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
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
	e2:SetCountLimit(1,id)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetTargetRange(LOCATION_GRAVE,0)
	c:RegisterEffect(e3)
	--Redirect
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e4:SetCondition(s.rmcon)
	e4:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e4)
	--Activate self from Banished
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_ACT_IN_RANGE)
	e5:SetRange(LOCATION_REMOVED)
	e5:SetCondition(aux.AND(newEffect.ActInRange.LimitCon(),s.actcon))
	e5:SetValue(newEffect.ActInRange.LimitOp())
	e5:SetCountLimit(1,{id,1})
	c:RegisterEffect(e5)
end
s.listed_series={ARCHETYPE_SPIRITUAL_ART}
--Activate from Deck/GY
function s.acttg(e,c)
	return c:IsSetCard(ARCHETYPE_SPIRITUAL_ART) and not c:IsCode(id) and c:IsFieldSpell()
end
--Redirect
function s.rmcon(e)
	local c=e:GetHandler()
	return c:IsFaceup() and c:IsLocation(LOCATION_FZONE)
end
--Activate self from Banished
function s.filter(c)
	return c:IsSetCard(ARCHETYPE_SPIRITUAL_ART) and c:IsFieldSpell() and c:IsFaceup()
end
function s.actcon(e)
	return Duel.IsExistingMatchingCard(s.filter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
