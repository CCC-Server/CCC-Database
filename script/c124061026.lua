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
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetRange(LOCATION_REMOVED)
	e5:SetCountLimit(1,{id,1})
	e5:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e5:SetCondition(s.fscon)
	e5:SetOperation(s.fsop)
	c:RegisterEffect(e5)
end
s.listed_series={ARCHETYPE_SPIRITUAL_ART}
--Activate from Deck/GY
function s.acttg(e,c)
	return c:IsArchetype(ARCHETYPE_SPIRITUAL_ART) and not c:IsCode(id) and c:IsFieldSpell()
end
--Redirect
function s.rmcon(e)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_FZONE) then
		c:RegisterFlagEffect(id,RESET_EVENT+RESET_TODECK+RESET_TOGRAVE+RESET_TOFIELD+RESET_TOHAND,0,1)
		return true
	else
		return false
	end
end
--Activate self from Banished
function s.fscon(e,tp)
	return Duel.IsTurnPlayer(tp) and e:GetHandler():HasFlagEffect(id)
end
function s.fsop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetActivateEffect():IsActivatable(tp,true,true) then
		Duel.ActivateFieldSpell(c,e,tp,eg,ep,ev,re,r,rp)
	end
end
