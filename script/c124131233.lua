--파이고라 하스탄
local s,id=GetID()
function s.initial_effect(c)
	--①: 자신 필드에 암석족 융합 몬스터가 존재할 경우, 이 카드를 패에서 특수 소환할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
    	--atk
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.cona)
    e2:SetTarget(aux.TargetBoolFunction(s.filter))
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)
	--def
	local e5=e2:Clone()
	e5:SetCondition(s.cond)
	c:RegisterEffect(e5)
end
function s.filter(c)
    return c:IsRace(RACE_ROCK) and c:IsType(TYPE_FUSION)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
end
function s.cona(e)
	return e:GetHandler():IsAttackPos() and (Duel.IsTurnPlayer(e:GetHandlerPlayer()) and Duel.IsBattlePhase())
end
function s.cond(e)
	return e:GetHandler():IsDefensePos() and (Duel.IsTurnPlayer(e:GetHandlerPlayer()) and Duel.GetCurrentPhase()==PHASE_MAIN1)
end
function s.immval(e,te)
    return te:GetOwnerPlayer()==1-e:GetHandlerPlayer() 
end