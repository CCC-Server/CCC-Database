local s,id=GetID()
function s.initial_effect(c)

	------------------------------------------------------
	-- ① Activate → Remove non-Librarian Spell and copy it + search Librarian Spell
	------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.tgtg1)
	e1:SetOperation(s.tgop1)
	c:RegisterEffect(e1)

	------------------------------------------------------
	-- ② GY → Banish this card to copy a Spell's effect
	------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.tgtg2)
	e2:SetOperation(s.tgop2)
	c:RegisterEffect(e2)
end


------------------------------------------------------
-- Summon restriction
------------------------------------------------------
function s.actcon(e,tp)
	return Duel.GetActivityCount(tp,ACTIVITY_SUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0
end



------------------------------------------------------
-- ① Remove non-Librarian Spell, activate it, then search Librarian Spell
------------------------------------------------------

function s.fakefilter(c)
	return c:IsType(TYPE_SPELL)
		and not c:IsSetCard(0x768)
		and c:IsAbleToRemove()
		and c:GetActivateEffect()~=nil
end

function s.splibrarianfilter(c)
	return c:IsSetCard(0x768)
		and c:IsType(TYPE_SPELL)
		and c:IsAbleToHand()
end

function s.tgtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fakefilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.splibrarianfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local tc=Duel.SelectMatchingCard(tp,s.fakefilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if not tc then return end
	if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)==0 then return end

	-- Copy removed Spell's activation effect
	local te=tc:GetActivateEffect()
	if te then
		local cost=te:GetCost()
		local target=te:GetTarget()
		local op=te:GetOperation()
		if cost then cost(te,tp,eg,ep,ev,re,r,rp,1) end
		if target then target(te,tp,eg,ep,ev,re,r,rp,1) end
		if op then op(te,tp,eg,ep,ev,re,r,rp) end
	end

	-- Then search Librarian Spell
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=Duel.SelectMatchingCard(tp,s.splibrarianfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end



------------------------------------------------------
-- ② GY: Copy Spell from your GY
------------------------------------------------------
function s.copyfilter(c)
	return c:IsType(TYPE_SPELL) and c:GetActivateEffect()
end

function s.tgtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
end

function s.tgop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
	local tc=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if not tc then return end

	Duel.Hint(HINT_CARD,tp,tc:GetOriginalCode())

	local te=tc:GetActivateEffect()
	if not te then return end

	local cost=te:GetCost()
	local target=te:GetTarget()
	local op=te:GetOperation()

	if cost then cost(te,tp,eg,ep,ev,re,r,rp,1) end
	if target then target(te,tp,eg,ep,ev,re,r,rp,1) end
	if op then op(te,tp,eg,ep,ev,re,r,rp) end
end
