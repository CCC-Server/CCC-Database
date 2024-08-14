--뱀파이어 빌리지 오우거샤이어
    local s,id=GetID()
    function s.initial_effect(c)
        --Activate
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_ACTIVATE)
        e1:SetCode(EVENT_FREE_CHAIN)
        c:RegisterEffect(e1)
        --change race
	    local e2=Effect.CreateEffect(c)
	    e2:SetType(EFFECT_TYPE_IGNITION)
	    e2:SetRange(LOCATION_FZONE)
	    e2:SetCountLimit(1,id)
	    e2:SetTarget(s.rctg)
        e2:SetCost(s.rccost)
	    e2:SetOperation(s.rcop)
	    c:RegisterEffect(e2)
		--Location redirection
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e3:SetCode(EFFECT_TO_GRAVE_REDIRECT)
		e3:SetRange(LOCATION_FZONE)
		e3:SetTarget(s.rmtarget)
		e3:SetCondition(s.remcon)
		e3:SetTargetRange(0,LOCATION_DECK)
		e3:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e3)
	end
function s.rccost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.rctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.FaceupFilter(aux.NOT(Card.IsRace),RACE_ZOMBIE),tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
end
function s.rcop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(aux.NOT(Card.IsRace),RACE_ZOMBIE),tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g==0 then return end
	local c=e:GetHandler()
	for tc in g:Iter() do
		--Becomes ZOMBIE until the end of this turn
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_RACE)
		e1:SetValue(RACE_ZOMBIE)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e1)
	end
end
function s.rmtarget(e,c)
	return Duel.IsPlayerCanRemove(e:GetHandlerPlayer(),c)
end
function s.wrfilter(c)
	return c:IsFaceup() and c:IsLevelAbove(5) and c:IsSetCard(0x8e)
end
function s.remcon(e)
	return Duel.IsExistingMatchingCard(s.wrfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end