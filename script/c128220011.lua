--그럿지아이유의 감옥
local s,id=GetID()
function c128220011.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
function s.thfilter(c)
	return c:IsCode(128220000) and c:IsMonster()
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	--
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.tg)
	e1:SetCode(EFFECT_DISABLE)
	if Duel.GetTurnPlayer()~=tp then
		e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,2)
	else
		e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
	end
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_ATTACK)
	Duel.RegisterEffect(e2,tp)
	--
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetTargetRange(1,1)
	e3:SetTarget(s.splimit)
	if Duel.GetTurnPlayer()~=tp then
		e3:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,2)
	else
		e3:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
	end
	Duel.RegisterEffect(e3,tp)
end
function s.tg(e,c)
	return c:IsType(TYPE_FUSION+TYPE_XYZ)
end
function s.splimit(e,c,tp,sumtp,sumpos)
	return (sumtp&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION or (sumtp&SUMMON_TYPE_XYZ)==SUMMON_TYPE_XYZ
end