-- Antique Gear Gadget Dragon
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

-- 소환 성공시 릴리스 종류에 따라 효과 부여
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetLabelObject()
	if not rc then return end

	-- EARTH: 패의 가제트 어드밴스 소환
	if rc:IsSetCard(0x51) and rc:IsAttribute(ATTRIBUTE_EARTH) then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetCategory(CATEGORY_SUMMON)
		e1:SetType(EFFECT_TYPE_QUICK_O)
		e1:SetCode(EVENT_FREE_CHAIN)
		e1:SetHintTiming(TIMING_MAIN_END+TIMING_BATTLE_PHASE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCountLimit(1,{id,1})
		e1:SetTarget(s.advsumtg)
		e1:SetOperation(s.advsumop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end

	-- LIGHT: 마/함 무효 + 파괴
	if rc:IsSetCard(0x51) and rc:IsAttribute(ATTRIBUTE_LIGHT) then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
		e2:SetCode(EVENT_CHAINING)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCountLimit(1,{id,2})
		e2:SetCondition(s.negcon)
		e2:SetCost(s.negcost)
		e2:SetTarget(s.negtg)
		e2:SetOperation(s.negop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	-- Fortress Trap: 어드밴스 이외 릴리스 불가
	if rc:IsCode(3955608,42237854,128770412,128770413) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e3:SetRange(LOCATION_MZONE)
		e3:SetValue(1)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-- EARTH: 패의 가제트 어드밴스 소환
function s.advfilter(c)
	return c:IsSetCard(0x51) and c:IsSummonable(true,nil)
end
function s.advsumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.advfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,tp,LOCATION_HAND)
end
function s.advsumop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.advfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
end

-- LIGHT: 마/함 발동 무효 + 파괴
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and Duel.IsChainDisablable(ev)
end
function s.costfilter1(c)
	return c:IsSetCard(0x51) and c:IsAbleToDeckAsCost()
end
function s.costfilter2(c)
	return c:IsDestructable()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.IsExistingMatchingCard(s.costfilter1,tp,LOCATION_GRAVE,0,1,nil)
	local g2=Duel.IsExistingMatchingCard(s.costfilter2,tp,LOCATION_ONFIELD,0,1,nil)
	if chk==0 then return g1 or g2 end
	local opt
	if g1 and g2 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif g1 then opt=0 else opt=1 end
	if opt==0 then
		local tg=Duel.SelectMatchingCard(tp,s.costfilter1,tp,LOCATION_GRAVE,0,1,1,nil)
		Duel.SendtoDeck(tg,nil,SEQ_DECKBOTTOM,REASON_COST)
	else
		local tg=Duel.SelectMatchingCard(tp,s.costfilter2,tp,LOCATION_ONFIELD,0,1,1,nil)
		Duel.Destroy(tg,REASON_COST)
	end
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end
