--나우프라테 에듀케이터 세뇨라
local s,id=GetID()
function s.initial_effect(c)
	--link
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,3,s.linkfilter)
	--effect 1
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.con1)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	--effect 2
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.cst2)
	e2:SetTarget(s.tg2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end

--link
function s.linkfilter(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0xf28,lc,sumtype,tp)
end

--effect 1
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler()~=e:GetHandler()
end

function s.tg1gfilter(c)
	return c:IsSetCard(0xf28) and c:IsAbleToGrave()
end

function s.tg1filter(c,e)
	return c:IsCanBeEffectTarget(e) and c:IsAbleToHand()
end

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)   
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and s.tg1filter(chkc,e) end
	local gg=Duel.GetMatchingGroup(s.tg1gfilter,tp,LOCATION_DECK,0,nil)
	local g=Duel.GetMatchingGroup(s.tg1filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,e:GetHandler(),e)
	if chk==0 then return #gg>0 and #g>0 and e:GetHandler():GetLinkedGroupCount()>0 end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,math.min(e:GetHandler():GetLinkedGroupCount(),#gg),aux.TRUE,1,tp,HINTMSG_RTOHAND)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,gg,#sg,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,sg,#sg,0,0)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	local gg=Duel.GetMatchingGroup(s.tg1gfilter,tp,LOCATION_DECK,0,nil)
	if #tg>0 and #gg>=#tg then
		local gsg=aux.SelectUnselectGroup(gg,e,tp,#tg,#tg,aux.TRUE,1,tp,HINTMSG_TOGRAVE)
		if Duel.SendtoGrave(gsg,REASON_EFFECT)>0 then
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
		end
	end
end

--effect 2
function s.cst2filter(c)
	return c:IsContinuousTrap() and c:IsTrapMonster() and c:IsAbleToRemoveAsCost()
end

function s.cst2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.cst2filter,tp,LOCATION_GRAVE,0,nil)
	if chk==0 then return #g>0 end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_REMOVE)
	Duel.Remove(sg,POS_FACEUP,REASON_COST)
end

function s.tg2filter(c)
	return c:IsSetCard(0xf28) and c:IsSpellTrap() and c:IsAbleToHand()
end

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.tg2filter,tp,LOCATION_GRAVE,0,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.tg2filter,tp,LOCATION_GRAVE,0,nil)
	if #g>0 then
		local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_ATOHAND)
		if Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,sg)
			Duel.BreakEffect()
			local dg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_HAND,0,nil)
			local dsg=aux.SelectUnselectGroup(dg,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_TOGRAVE)
			Duel.SendtoGrave(dsg,REASON_EFFECT)
		end
	end
end