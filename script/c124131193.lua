--십이신좌제 이아손
local s,id=GetID()
function s.initial_effect(c)
	--link summon
	Link.AddProcedure(c,nil,2,2)
	c:EnableReviveLimit()
	--destroy replace
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
    	--If sent to GY as link material, that link monster can make a second attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.matcon)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)
end
function s.repfilter(c,tp,hc)
	return c:IsFaceup() and c:IsLocation(LOCATION_MZONE) and not c:IsReason(REASON_REPLACE) 
		and c:IsControler(tp) and c:IsReason(REASON_EFFECT) and hc:GetLinkedGroup():IsContains(c)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGrave() and eg:IsExists(s.repfilter,1,nil,tp,e:GetHandler()) end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer(),e:GetHandler())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SendtoGrave(e:GetHandler(),REASON_EFFECT)
end
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsLocation(LOCATION_GRAVE)
		and r & REASON_LINK == REASON_LINK and e:GetHandler():GetReasonCard():IsLinkMonster()
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sc=c:GetReasonCard()
	if sc and sc:IsFaceup() and sc:IsOnField() then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3201)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		sc:RegisterEffect(e1)
	end
end