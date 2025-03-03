local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_LIGHT|ATTRIBUTE_EARTH|ATTRIBUTE_WIND),1,99,s.fusfilter)

	-- (1) 융합 소환 시 효과 적용
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	e2:SetCondition(s.indcon)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetValue(1)
	e3:SetCondition(s.indcon)
	c:RegisterEffect(e3)

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.efilter)
	e4:SetCondition(s.indcon)
	c:RegisterEffect(e4)

	-- (2) 전체 공격 효과
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_ATTACK_ALL)
	e5:SetValue(1)
	c:RegisterEffect(e5)

	-- (3) 배틀 페이즈 중 어드밴스 소환 (차후 작업)
	--[[
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetHintTiming(TIMING_BATTLE_PHASE)
	e6:SetCondition(s.advcon)
	e6:SetTarget(s.advtg)
	e6:SetOperation(s.advop)
	c:RegisterEffect(e6)
	--]]
end

-- 융합 소재 필터 (레벨 6 이상의 "U.K" 몬스터)
function s.fusfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x42d,fc,st,tp) and c:IsLevelAbove(6)
end

function s.indcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.efilter(e,te)
	return te:IsActiveType(TYPE_MONSTER)
end

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local mg=Duel.GetFusionMaterial(tp):Filter(Card.IsOnField,nil)+Duel.GetFusionMaterial(1-tp):Filter(Card.IsOnField,nil)
	if chk==0 then return Duel.IsExistingMatchingCard(Fusion.SummonEff(tp,nil,mg,nil,nil,nil,true),tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetFusionMaterial(tp):Filter(Card.IsOnField,nil)+Duel.GetFusionMaterial(1-tp):Filter(Card.IsOnField,nil)
	Fusion.SummonEff(tp,nil,mg,nil,nil,nil,true)
end

