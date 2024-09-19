--십이신좌제 문지기
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon itself from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetValue(s.spval)
	c:RegisterEffect(e1)
	--A link monster using this card cannot be destroyed by battle or card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.lkcon)
	e2:SetOperation(s.lkop)
	c:RegisterEffect(e2)
end
function s.spval(e,c)
	return 0,aux.GetMMZonesPointedTo(c:GetControler(),Card.IsSetCard,nil,nil,nil,0x820)
end
	--If sent as link material
    function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
        return r==REASON_LINK
    end
        --A link monster using this card cannot be destroyed by battle or card effects this turn
    function s.lkop(e,tp,eg,ep,ev,re,r,rp)
        local c=e:GetHandler()
        local rc=c:GetReasonCard()
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(3008)
        e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        rc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
        rc:RegisterEffect(e2)
    end