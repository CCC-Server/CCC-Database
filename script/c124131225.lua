--네가로기어 주피스터
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	Xyz.AddProcedure(c,nil,12,2,s.xyzfilter,aux.Stringid(id,0),2,s.xyzop)
	c:EnableReviveLimit()
	--자신 / 상대 턴에, 이 카드의 엑시즈 소재를 2개 제거하고 발동할 수 있다. 필드의 다른 몬스터의 효과를 전부 무효화한다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCost(aux.dxmcostgen(2,2,nil))
	e1:SetOperation(s.gyop)
	c:RegisterEffect(e1)
	--handes
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.hdcon)
	e3:SetTarget(s.hdtg)
	e3:SetOperation(s.hdop)
	c:RegisterEffect(e3)
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if (a and a:IsType(TYPE_XYZ)) or (d and d:IsType(TYPE_XYZ)) then
		Duel.RegisterFlagEffect(0,90448280,RESET_PHASE+PHASE_END,0,1)
	end
end
function s.xyzfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ,xyzc,SUMMON_TYPE_XYZ,tp)
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,90448279)==0 and Duel.GetFlagEffect(0,90448280)>0 end
	Duel.RegisterFlagEffect(tp,90448279,RESET_PHASE+PHASE_END,0,1)
	return true
end
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.negfilter,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end
function s.attfilter(c,e)
	return not c:IsImmuneToEffect(e)
end
function s.hdcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()~=PHASE_DRAW and eg:IsExists(s.cfilter,1,nil,1-tp)
end
function s.cfilter(c,tp)
	return c:IsControler(tp) and c:IsPreviousLocation(LOCATION_DECK)
end
function s.hdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsRelateToEffect(e) and e:GetHandler():IsFaceup() 
		and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_HAND,1,nil) end
end
function s.hdop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_HAND,nil)
    local tc=Duel.GetFirstTarget()
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.Overlay(c,sg,true)
	end
end