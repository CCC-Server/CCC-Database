--slipknot - psychosocial
local s,id=GetID()
function c128220051.initial_effect(c)
	--Add 1 "Slipknot" monster from your Deck to your hand, then, if your opponent controls a monster, you can Dertroy Cards
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.thfilter(c)
	return c:IsSetCard(0xc22) and c:IsMonster() and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	local g1=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	if chk==0 then return #g1>0 and #g2>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1+g2,2,tp,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		Duel.ShuffleHand(tp)
		Duel.ShuffleDeck(tp)
		if Duel.GetMatchingGroupCount(nil,tp,0,LOCATION_MZONE,nil)>0 then
			local g=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,LOCATION_ONFIELD)
	if #g<2 then return end
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.dpcheck(Card.GetControler),1,tp,HINTMSG_DESTROY)
	if #sg==2 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.HintSelection(g)
		Duel.BreakEffect()
		Duel.Destroy(sg,REASON_EFFECT)
	end
		end
	end
end