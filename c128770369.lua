local s,id=GetID()
function s.initial_effect(c)

	----------------------------------------------------
	-- Effect ①: Activate → Search "Spell Librarian"
	----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	----------------------------------------------------
	-- Effect ②: GY → banish this; activate QP from Deck
	----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost) -- banish this card from GY as cost
	e2:SetTarget(s.qptg)
	e2:SetOperation(s.qpop)
	c:RegisterEffect(e2)
end


----------------------------------------------------
-- Summon restriction for Effect ①
----------------------------------------------------
function s.actcon(e,tp)
	return Duel.GetActivityCount(tp,ACTIVITY_SUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0
end


----------------------------------------------------
-- Effect ①: Search Spell Librarian Spell
----------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x768) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- 필터: 덱에서 발동 가능한 속공 마법
----------------------------------------------------
-- Effect ②: GY → Banish this; Activate QP Spell from Deck
----------------------------------------------------
----------------------------------------------------
-- Effect ②: GY → Banish this; Activate QP Spell from Deck
----------------------------------------------------
----------------------------------------------------
-- Effect ②: GY → Banish this; Activate 1 QP Spell from Deck
----------------------------------------------------
----------------------------------------------------
-- Effect ②: GY banish → Activate 1 Quick-Play Spell from Deck
----------------------------------------------------
----------------------------------------------------
-- Effect ②: GY banish → Send 1 Quick-Play Spell from Deck to GY,
-- then apply its activation effect.
----------------------------------------------------
function s.qpfilter(c,tp)
	return c:IsType(TYPE_QUICKPLAY) and c:IsSpell()
		and c:CheckActivateEffect(false,true,false) ~= nil
end

function s.qptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.qpfilter,tp,LOCATION_DECK,0,1,nil,tp)
	end
end

function s.qpop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,0)
	local sc = Duel.SelectMatchingCard(tp,s.qpfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if not sc then return end

	-- ① 덱에서 속공 마법을 묘지로 보냄
	Duel.DisableShuffleCheck()
	if Duel.SendtoGrave(sc,REASON_EFFECT)==0 then return end

	-- ② 그 속공 마법의 "발동시 효과" 정보 가져오기
	local te = sc:GetActivateEffect()
	if not te then return end

	local cost = te:GetCost()
	local tg   = te:GetTarget()
	local op   = te:GetOperation()

	Duel.ClearTargetCard()

	-- ③ 발동시 효과의 cost 적용
	if cost then cost(te,tp,eg,ep,ev,re,r,rp,1) end

	-- ④ 발동시 효과의 target 적용
	if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end

	-- ⑤ 발동시 효과의 operation 적용 (체인 없이 즉시 실행)
	if op then op(te,tp,eg,ep,ev,re,r,rp) end
end

