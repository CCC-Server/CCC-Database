local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------------------------------------
	-- Xyz Summon (Rank 4, 2 Materials)
	---------------------------------------------------------------------
	Xyz.AddProcedure(c,nil,4,2)
	c:EnableReviveLimit()

	---------------------------------------------------------------------
	-- Effect 1: Quick / Detach 1 → Reveal 3 from OPP deck → Stack → SS on opp turn
	---------------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost1)
	e1:SetOperation(s.operation1)
	c:RegisterEffect(e1)

	---------------------------------------------------------------------
	-- Effect 2: Opp monster effect → negate + change race
	---------------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

---------------------------------------------------------------------
-- Effect 1 cost: detach 1
---------------------------------------------------------------------
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

---------------------------------------------------------------------
-- Effect 1: operation
-- ★ opponent deck top 3 reveal + reorder
---------------------------------------------------------------------
function s.operation1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- OPPONENT deck must have at least 3 cards
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0) < 3 then return end

	-- Step 1: Reveal opponent deck top 3
	Duel.ConfirmDecktop(1-tp,3)

	local g=Duel.GetDecktopGroup(1-tp,3)
	if #g==0 then return end

	-- Step 2: reorder their deck
	Duel.SortDecktop(1-tp,1-tp,3)

	-- Step 3: If opponent's turn → SS a “Stellaron Hunter”
	if Duel.GetTurnPlayer()~=tp then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.sphfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #sg>0 then
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- “Stellaron Hunter” monster filter
function s.sphfilter(c,e,tp)
	return c:IsSetCard(0xc47) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

---------------------------------------------------------------------
-- Effect 2 condition
---------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainDisablable(ev)
end

---------------------------------------------------------------------
-- Effect 2 target
---------------------------------------------------------------------
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=re:GetHandler()
	if chk==0 then return tc and tc:IsOnField() end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,tc,1,0,0)
end

---------------------------------------------------------------------
-- Effect 2 negate + race change
---------------------------------------------------------------------
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tc=re:GetHandler()
	if tc and tc:IsRelateToEffect(re) and tc:IsFaceup() then
		-- negate
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)

		-- change race → CYBERSE
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_CHANGE_RACE)
		e3:SetValue(RACE_CYBERSE)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e3)
	end
end
