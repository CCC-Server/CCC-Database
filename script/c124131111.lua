--포레드런 시리아
local s,id=GetID()
function s.initial_effect(c)
	--"포레드런" 존재할때 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	--indes
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.indcon)
	e2:SetTarget(s.indtg)
	e2:SetValue(1)
	c:RegisterEffect(e2)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x81d),tp,LOCATION_MZONE,0,1,nil)
end

function s.confilter(c)
	return c:IsFaceup() and (c:IsLevelAbove(5) or c:IsRankAbove(5) or c:IsLinkAbove(3))
end

function s.indcon(e)
	return Duel.IsExistingMatchingCard(s.confilter,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil)
end

function s.indtg(e,c)
	return c:IsSetCard(0x81d) and c:IsLevel(3)
end