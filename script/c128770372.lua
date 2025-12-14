local s,id=GetID()
function s.initial_effect(c)

	-----------------------------------------------------
	-- ① 이 카드 발동 → 묘지/제외 Spell 1장 회수
	-----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-----------------------------------------------------
	-- ② 묘지: 이 카드를 제외하고 → "Spell Librarian" 지속마법 발동
	-----------------------------------------------------
   -- E2: GY Quick Effect - Banish this card to place a "Spell -- E2: GY Quick Effect - Banish this card to place a "Spell Librarian" Continuous Spell from Deck
-- E2: GY Quick Effect
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id, 1))
e2:SetType(EFFECT_TYPE_QUICK_O)
e2:SetCode(EVENT_FREE_CHAIN)
e2:SetRange(LOCATION_GRAVE)
e2:SetCountLimit(1, id+100)
e2:SetCost(aux.bfgcost)
e2:SetTarget(s.settg)
e2:SetOperation(s.setop)
c:RegisterEffect(e2)

end


-----------------------------------------------------
-- Summon restriction (발동 조건)
-----------------------------------------------------
function s.actcon(e,tp)
	return Duel.GetActivityCount(tp,ACTIVITY_SUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0
end


-----------------------------------------------------
-- ① Spell retrieval
-----------------------------------------------------
function s.thfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end


-----------------------------------------------------
-- ② Activate Continuous Spell Librarian card from Deck
-----------------------------------------------------
function s.setfilter(c)
	return c:IsSetCard(0x768)
		and c:IsType(TYPE_SPELL)
		and c:IsType(TYPE_CONTINUOUS)
		and c:GetActivateEffect() ~= nil
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end
