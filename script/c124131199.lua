--십이신좌의 산맥
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--atkup
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsType,TYPE_LINK))
	e2:SetValue(700)
	c:RegisterEffect(e2)
    --cannot be target
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(0,LOCATION_MZONE)
	e4:SetValue(s.atlimit)
	c:RegisterEffect(e4)
end
function s.atfilter(c,atk)
	return c:IsFaceup() and c:IsLinkMonster() and c:GetAttack()>atk
end
function s.atlimit(e,c)
	return c:IsFaceup() and c:IsLinkMonster() and Duel.IsExistingMatchingCard(s.atfilter,c:GetControler(),LOCATION_MZONE,0,1,nil,c:GetAttack())
end
