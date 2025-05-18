--테이베르스-폭염의 탐구자 자드라콘
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc03),1,1,Synchro.NonTunerEx(Card.IsSetCard, 0xc03),1,1)
	c:EnableReviveLimit()
	--lv change
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetCountLimit(1,id)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e2:SetValue(s.immval2)
	c:RegisterEffect(e3)
end
s.listed_series={0xc03}
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local lv=e:GetHandler():GetLevel()
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
	e:SetLabel(Duel.AnnounceLevel(tp,1,8,lv))
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(e:GetLabel())
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end
function s.immcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_SYNCHRO
end
function s.immval(e,te)
	local tc=te:GetOwner()
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
		and te:IsActiveType(TYPE_SPELL) and te:IsActivated() and te:GetActivateLocation()==LOCATION_SZONE
end
function s.immval2(e,te)
	local tc=te:GetOwner()
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
		and te:IsActiveType(TYPE_TRAP) and te:IsActivated() and te:GetActivateLocation()==LOCATION_SZONE
end