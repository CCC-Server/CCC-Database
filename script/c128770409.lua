-- Antique Gear Reactor Gadget Dragon
local s,id=GetID()
function s.initial_effect(c)
	-- 어드밴스 소환 (가제트 1장으로 가능)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCondition(s.sumcon)
	e0:SetOperation(s.sumop)
	c:RegisterEffect(e0)

	-- 소환 성공시 효과 부여
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.regop)
	c:RegisterEffect(e1)
end

-- 어드밴스 소환 조건
function s.gadgetfilter(c)
	return c:IsSetCard(0x51) and c:IsReleasable()
end
function s.sumcon(e,c,minc)
	if c==nil then return true end
	return minc==1 and Duel.CheckTribute(c,1,1,s.gadgetfilter)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,1,1,s.gadgetfilter)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
	local rc=g:GetFirst()
	c:SetLabelObject(rc)
end

-- 소환 성공 시 릴리스 종류에 따른 효과 부여
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetLabelObject()
	if not rc then return end

	-- EARTH: 마/함 효과 무효
	if rc:IsSetCard(0x51) and rc:IsAttribute(ATTRIBUTE_EARTH) then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end

	-- LIGHT: 배틀 페이즈에 파괴
	if rc:IsSetCard(0x51) and rc:IsAttribute(ATTRIBUTE_LIGHT) then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetCategory(CATEGORY_DESTROY)
		e2:SetType(EFFECT_TYPE_QUICK_O)
		e2:SetCode(EVENT_FREE_CHAIN)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCountLimit(1,{id,1})
		e2:SetHintTiming(TIMING_BATTLE_PHASE+TIMING_BATTLE_START+TIMING_BATTLE_STEP)
		e2:SetCondition(s.descon)
		e2:SetTarget(s.destg)
		e2:SetOperation(s.desop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	-- Fortress: 3회 공격
	if rc:IsCode(3955608,42237854,128770412,128770413) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
		e3:SetValue(2)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-- EARTH: 마/함 효과 무효
function s.efilter(e,te)
	return te:IsActiveType(TYPE_SPELL+TYPE_TRAP) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- LIGHT: 배틀 페이즈에 상대 카드 파괴
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end
function s.countfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0x51) or c:IsCode(3955608,42237854,128770412,128770413))
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.countfilter,tp,LOCATION_ONFIELD,0,nil)
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.countfilter,tp,LOCATION_ONFIELD,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,ct,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
