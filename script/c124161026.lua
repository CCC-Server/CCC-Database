--Pyrthirio Etna
local s,id=GetID()
function s.initial_effect(c)
	--activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--effect 1
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(_,c) return c:IsSetCard(0xf21) end)
	e1:SetValue(s.val1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	--effect 2
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id)
	e3:SetCost(s.cst2)
	e3:SetTarget(s.tg2)
	e3:SetOperation(s.op2)
	c:RegisterEffect(e3)
	--effect 3
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.con3)
	e4:SetTarget(s.tg3)
	e4:SetOperation(s.op3)
	c:RegisterEffect(e4)
end

--effect 1
function s.val1(e,c,tc)
	local tp=e:GetHandlerPlayer()
	local unu=20-Duel.GetLocationCount(tp,LOCATION_MZONE)-Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)+Duel.GetFieldGroupCount(tp,LOCATION_EMZONE,0)-Duel.GetLocationCount(tp,LOCATION_SZONE)-Duel.GetFieldGroupCount(tp,LOCATION_SZONE,0)+Duel.GetFieldGroupCount(tp,LOCATION_FZONE,0)
	-Duel.GetLocationCount(1-tp,LOCATION_MZONE)-Duel.GetFieldGroupCount(1-tp,LOCATION_MZONE,0)+Duel.GetFieldGroupCount(1-tp,LOCATION_EMZONE,0)-Duel.GetLocationCount(1-tp,LOCATION_SZONE)-Duel.GetFieldGroupCount(1-tp,LOCATION_SZONE,0)+Duel.GetFieldGroupCount(1-tp,LOCATION_FZONE,0)

	local exunu=0
	if Duel.GetFieldGroupCount(tp,LOCATION_EMZONE,0)+Duel.GetFieldGroupCount(1-tp,LOCATION_EMZONE,0)==2 then
		exunu=0
	elseif Duel.GetFieldGroupCount(tp,LOCATION_EMZONE,0)+Duel.GetFieldGroupCount(1-tp,LOCATION_EMZONE,0)==1 then
		exunu=1-Duel.GetLocationCountFromEx(tp,tp,tc,c,ZONES_EMZ)-Duel.GetLocationCountFromEx(1-tp,1-tp,tc,c,ZONES_EMZ)
	else
		exunu=2-Duel.GetLocationCountFromEx(tp,tp,tc,c,0x20)-Duel.GetLocationCountFromEx(tp,tp,tc,c,0x40)
	end  
	return (unu+exunu)*100
end

--effect 2
function s.cst2filter(c,tp)
	return c:IsSetCard(0xf21) and not c:IsType(TYPE_FIELD) and c:IsAbleToGraveAsCost()
end

function s.cst2(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.cst2filter,tp,LOCATION_DECK,0,nil,e,tp)
	if chk==0 then return #g>0 end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_TOGRAVE)
	Duel.SendtoGrave(sg,REASON_COST)
end

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE,PLAYER_NONE,0)+Duel.GetLocationCount(tp,LOCATION_SZONE,PLAYER_NONE,0)+Duel.GetLocationCount(1-tp,LOCATION_MZONE,PLAYER_NONE,0)+Duel.GetLocationCount(1-tp,LOCATION_SZONE,PLAYER_NONE,0)>0 end
	local dis=Duel.SelectDisableField(tp,1,LOCATION_ONFIELD,LOCATION_ONFIELD,0)
	Duel.Hint(HINT_ZONE,tp,dis)
	e:SetLabel(dis)
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
	c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetOperation(function(e) return e:GetLabel() end)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetLabel(e:GetLabel())
	c:RegisterEffect(e1)
end

--effect 3
function s.con3filter(c,tp)
	return c:IsPreviousPosition(POS_FACEUP) and c:IsType(TYPE_FUSION) and c:IsPreviousSetCard(0xf21) and c:IsPreviousControler(tp) and c:GetReasonPlayer()==1-tp
end

function s.con3(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.con3filter,1,nil,tp)
end

function s.tg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE,PLAYER_NONE,0)+Duel.GetLocationCount(1-tp,LOCATION_SZONE,PLAYER_NONE,0)>1 end
	local dis=Duel.SelectDisableField(tp,2,0,LOCATION_ONFIELD,0)
	Duel.Hint(HINT_ZONE,tp,dis)
	e:SetLabel(dis)
end

function s.op3(e,tp,eg,ep,ev,re,r,rp)
	c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetOperation(function(e) return e:GetLabel() end)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	e1:SetLabel(e:GetLabel())
	Duel.RegisterEffect(e1,tp)
end