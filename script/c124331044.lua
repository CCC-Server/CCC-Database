--드래곤블러드 캘큘러스
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetValue(function(e) e:SetLabel(1) end)
	e2:SetCondition(function(e)
		return Duel.IsExistingMatchingCard(s.tributefilter,e:GetHandlerPlayer(),LOCATION_ONFIELD|LOCATION_HAND,0,1,e:GetHandler(),e,tp)
	end)
	c:RegisterEffect(e2)
	e1:SetLabelObject(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetCountLimit(1,{id,1})
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_RELEASE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCondition(s.setcon)
	c:RegisterEffect(e4)
end
function s.tributefilter(c,loc,e,tp)
	return (c:IsType(TYPE_RITUAL) or c:IsSetCard(0xda3)) and c:IsAbleToGrave()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(100)
	local label_obj=e:GetLabelObject()
	if chk==0 then label_obj:SetLabel(0) return true end
	if label_obj:GetLabel()>0 then
		label_obj:SetLabel(0)
		local rg=Duel.SelectMatchingCard(tp,s.tributefilter,tp,LOCATION_ONFIELD|LOCATION_HAND,0,1,1,e:GetHandler(),e,tp)
		Duel.SendtoGrave(rg,REASON_RELEASE+REASON_COST)
	end
end
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xda3) and c:IsMonster()
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil) then return false end
	return Duel.IsChainNegatable(ev) and re:GetHandler():IsSpellTrap() and ep==1-tp
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp,c)
		--Banish it if it leaves the field
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3300)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1)
	end
end
function s.setfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsType(TYPE_RITUAL)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.setfilter,1,nil,tp)
end