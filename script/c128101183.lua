--Cyber Obliterator Dragon
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Fusion material
	Fusion.AddProcMixN(c,true,true,s.matfilter,3)

	-- ①: Destroy all opponent's monsters when Fusion Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- ②: Unaffected by opponent's effects if summoned via Power Bond
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)

	-- ③: Attack all opponent's monsters once each + piercing
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_ATTACK_ALL)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e4)
end

-- Fusion Material Filter: "Cyber Dragon" or "Cyberdark"
function s.matfilter(c,fc,sumtype,tp)
	return c:IsMonster() and (c:IsSetCard(0x1093) or c:IsSetCard(0x4093)) -- 0x1093 = Cyber Dragon, 0x11A = Cyberdark
end

-- ①: Destroy all opponent's monsters
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- ②: Power Bond immunity
function s.immcon(e)
	local c=e:GetHandler()
	local re=c:GetReasonEffect()
	return c:IsSummonType(SUMMON_TYPE_FUSION) and re and re:GetHandler():IsCode(37630732) -- Power Bond
end
function s.immval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
