--드래곤블러드 포팅
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.dthcost)
	e1:SetTarget(s.dthtg)
	e1:SetOperation(s.dthop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
	e2:SetValue(function(e) e:SetLabel(1) end)
	e2:SetCondition(function(e)
		return Duel.IsExistingMatchingCard(s.tributefilter,e:GetHandlerPlayer(),LOCATION_ONFIELD|LOCATION_HAND,0,1,e:GetHandler(),e,tp)
	end)
	c:RegisterEffect(e2)
	e1:SetLabelObject(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetCountLimit(1,{id,1})
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_RELEASE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetTarget(s.regtg)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)
end
function s.tributefilter(c,loc,e,tp)
	return (c:IsType(TYPE_RITUAL) or c:IsSetCard(0xda3)) and c:IsAbleToGrave()
end
function s.dthcost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(100)
	local label_obj=e:GetLabelObject()
	if chk==0 then label_obj:SetLabel(0) return true end
	if label_obj:GetLabel()>0 then
		label_obj:SetLabel(0)
		local rg=Duel.SelectMatchingCard(tp,s.tributefilter,tp,LOCATION_ONFIELD|LOCATION_HAND,0,1,1,e:GetHandler(),e,tp)
		Duel.SendtoGrave(rg,REASON_RELEASE+REASON_COST)
	end
end
function s.dthfilter(c)
	return c:IsSetCard(0xda3) and c:IsAbleToHand()
end
function s.dthtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.AND(s.dthfilter,Card.IsMonster),tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.dthop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.AND(s.dthfilter,Card.IsMonster),tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.regtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetCondition(s.thcon)
	e1:SetOperation(s.thop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.thfilter(c)
	return c:IsSetCard(0xda3) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,nil)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end