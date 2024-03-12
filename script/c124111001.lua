--고통의 결정
local s,id=GetID()
function s.initial_effect(c)
	--2 Draw
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,2)
			or Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_DECK,0,2,nil)
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=Duel.SelectEffect(tp,
		{Duel.IsPlayerCanDraw(tp,2),aux.Stringid(id,0)},
		{Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_DECK,0,2,nil),aux.Stringid(id,1)}
	)
	if op==1 then
		--Draw 2 cards, and then opponent can drop 2 cards
		if Duel.Draw(tp,2,REASON_EFFECT)>0
			and Duel.IsExistingMatchingCard(Card.IsAbleToGrave,1-tp,LOCATION_DECK,0,2,nil)
			and Duel.SelectYesNo(1-tp,aux.Stringid(id,3)) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
				local g=Duel.SelectMatchingCard(1-tp,Card.IsAbleToGrave,1-tp,LOCATION_DECK,0,2,2,nil)
				if #g>0 then
					Duel.BreakEffect()
					Duel.SendtoGrave(g,REASON_EFFECT)
				end
		end
	elseif op==2 then
		--Drop 2 cards, and then opponent can draw 2 cards
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,LOCATION_DECK,0,2,2,nil)
		if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0
			and Duel.IsPlayerCanDraw(1-tp,2)
			and Duel.SelectYesNo(1-tp,aux.Stringid(id,2)) then
				Duel.BreakEffect()
				Duel.Draw(1-tp,2,REASON_EFFECT)
		end
	end
end
