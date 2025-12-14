local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon procedure: 1 Tuner + 1+ non-Tuner FIRE
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,aux.FilterBoolFunction(s.matfilter),1,99)
	c:EnableReviveLimit()

	-- E1: On Synchro Summon - Search 2 cards, discard 2
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- E2: Quick effect - Banish FIRE to negate opponent's cards
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- Synchro material filter: Must be non-Tuner FIRE
function s.matfilter(c,scard,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and not c:IsType(TYPE_TUNER)
end

-- E1: On Synchro Summon
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.thfilter1(c)
	return c:IsSetCard(0x39) and c:IsAbleToHand() -- Laval
end
function s.thfilter2(c)
	return c:IsCode(72142276) and c:IsAbleToHand() -- Flame Transmission Seal
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
	local g2=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 and #g2>0 then
		g1:Merge(g2)
		if Duel.SendtoHand(g1,nil,REASON_EFFECT)~=0 then
			Duel.ConfirmCards(1-tp,g1)
			Duel.DiscardHand(tp,nil,2,2,REASON_EFFECT+REASON_DISCARD)
		end
	end
end

-- E2: Quick effect - Negate opponent's cards
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(1-tp) or Duel.IsTurnPlayer(tp)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_FIRE),tp,LOCATION_GRAVE,0,1,nil) end
	local g=Duel.SelectMatchingCard(tp,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_FIRE),tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.negfilter(c)
	return c:IsFaceup() and c:IsNegatable()
end
function s.lavalfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x39)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil)
	end
	local ct=Duel.GetMatchingGroupCount(s.lavalfilter,tp,LOCATION_MZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,ct,1-tp,LOCATION_ONFIELD)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.lavalfilter,tp,LOCATION_MZONE,0,nil)
	if ct==0 then return end
	local g=Duel.SelectMatchingCard(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,ct,nil)
	for tc in aux.Next(g) do
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end