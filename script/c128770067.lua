local s,id=GetID()
function s.initial_effect(c)
	-- 융합 소환
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_LIGHT|ATTRIBUTE_EARTH|ATTRIBUTE_WIND),1,99,s.fusfilter)

	-- (1) 융합 소환 시 효과 적용
	--[[
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)
	--]]

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

	-- (2) 추가 공격 효과
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e5:SetValue(s.extraatk)
	c:RegisterEffect(e5)

	-- (3) 배틀 페이즈 중 융합 소환
	local params = {nil,nil,function(e,tp,mg) return nil,s.fcheck end}
	local params = {nil,Fusion.CheckWithHandler(aux.FALSE),s.fextra,nil,Fusion.ForcedHandler}
	local params = {function(e,c) return c:IsSetCard(0x42d) and not c:IsCode(id) end,
		Fusion.OnFieldMat,
		function(e,tp,mg) return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsFaceup),tp,0,LOCATION_ONFIELD,nil) end,
		nil,
		Fusion.ForcedHandler
	}
	--function(fusfilter,matfilter,extrafil,extraop,gc2,stage2,exactcount,value,location,chkf,preselect,nosummoncheck,extratg)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetHintTiming(TIMING_BATTLE_PHASE)
	e6:SetCondition(s.fuscon)
	e6:SetTarget(Fusion.SummonEffTG(table.unpack(params)))
	e6:SetOperation(Fusion.SummonEffOP(table.unpack(params)))
	c:RegisterEffect(e6)
end

-- 융합 소재 필터 (레벨 6 이상의 "U.K" 몬스터)
function s.fusfilter(c,fc,st,tp)
	return c:IsSetCard(0x42d,fc,st,tp) and c:IsLevelAbove(6)
end


function s.indcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.efilter(e,te)
	return te:IsActiveType(TYPE_TRAP)
end

function s.extraatk(e,c)
	return c:GetMaterialCount()-1
end

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

function s.fcheck(tp,sg,fc)
	return sg:FilterCount(aux.AND(Card.IsControler,Card.IsOnField),nil,tp)==1
end

function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsFaceup),tp,0,LOCATION_ONFIELD,nil),s.fcheck
end
