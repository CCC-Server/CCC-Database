--〈영원한 후일담〉 촬영 중
local s,id=GetID()
function s.initial_effect(c)
	--activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_INACTIVATE)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCondition(s.condition)
	e4:SetValue(s.effectfilter)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_DISEFFECT)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCondition(s.condition)
	e5:SetValue(s.effectfilter)
	c:RegisterEffect(e5)
end
function s.confilter(c)
	return c:IsType(TYPE_NORMAL) and c:IsRace(RACE_ZOMBIE)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(s.confilter),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.effectfilter(e,ct)
	local p=e:GetHandler():GetControler()
	local te,tp,loc=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER,CHAININFO_TRIGGERING_LOCATION)
	return p==tp and te:GetHandler():IsSetCard(0x1fd0) and loc&LOCATION_ONFIELD~=0
end