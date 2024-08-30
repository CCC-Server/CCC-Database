--데 리퍼 ADR-08 옵티마이저
local s,id=GetID()
function s.initial_effect(c)
	c:EnableUnsummonable()
	c:SetUniqueOnField(1,0,id)
	--spsummon condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)
    --atkup
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.atkcon)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	--자신의 배틀 페이즈에, 자신 필드의 "데 리퍼" 몬스터는 상대의 몬스터 카드의 효과를 받지 않는다.
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetTargetRange(LOCATION_MZONE,0)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.con3)
	e5:SetTarget(s.tg3)
	e5:SetValue(s.val3)
	c:RegisterEffect(e5)
end
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsSetCard(0x810)
		and (se:IsHasType(EFFECT_TYPE_ACTIONS) or se:GetCode()==EFFECT_SPSUMMON_PROC)
end
function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(0x810)
end
function s.val(e,c)
	return Duel.GetMatchingGroupCount(s.filter,c:GetControler(),LOCATION_ONFIELD+LOCATION_FZONE,LOCATION_ONFIELD+LOCATION_FZONE,c)*500
end
function s.accon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,124131004),0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
end
function s.atkcon(e)
	local ph=Duel.GetCurrentPhase()
	local tp=Duel.GetTurnPlayer()
	return tp==e:GetHandler():GetControler() and ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end
function s.atkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x810)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_ONFIELD,0,nil)*500
end
function s.con3(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

function s.tg3(e,c)
	return c:IsSetCard(0x810) and c:IsMonster()
end

function s.val3(e,te)
	return te:IsActiveType(TYPE_MONSTER) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end