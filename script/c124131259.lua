-- 저승사자 뮤트
local s,id=GetID()
function s.initial_effect(c)
    -- Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
    -- Cannot attack
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_ATTACK)
    e2:SetCondition(s.atcon)
    c:RegisterEffect(e2)
    -- Additional Normal Summon
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_DAMAGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.nscon)
    e3:SetOperation(s.nsop)
    c:RegisterEffect(e3)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)>0
		and not Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.cfilter(c)
	return c:IsFacedown() or not c:IsRace(RACE_FIEND)
end


function s.atfilter(c)
	return c:IsFacedown() or not c:IsRace(RACE_FIEND)
end
function s.atcon(e)
	return Duel.IsExistingMatchingCard(s.atfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.nscon(e,tp,eg,ep,ev,re,r,rp)
    return ep==tp and (r&REASON_BATTLE+REASON_EFFECT)~=0
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFlagEffect(tp,id)>0 then return end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    -- Can Normal Summon 1 Fiend/DARK monster in addition to your Normal Summon/Set
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
    e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
    e1:SetTarget(aux.TargetBoolFunction(aux.FilterBoolFunction(Card.IsRace,RACE_FIEND),Card.IsAttribute,ATTRIBUTE_DARK))
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end