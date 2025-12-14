--스펠크래프트 숙제할거에요오!
local s,id=GetID()
function s.initial_effect(c)
	--① 발동
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

----------------------------------------
--① 발동 비용: 패 1장 버리기
----------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckRemoveOverlayCard(tp,1,0,0,REASON_COST) or Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND,0,1,1,e:GetHandler())
	Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

----------------------------------------
--① 서치 대상
----------------------------------------
function s.thfilter1(c)
	return c:IsSetCard(0x761) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thfilter2(c)
	return c:IsSetCard(0x761) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and not c:IsCode(128770289)  --"숙제할거에요오!" 자신 제외
		and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end

----------------------------------------
--① 발동 처리: 2장 서치 + 카운터 제거 시 파괴
----------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g1==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g2=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
	if #g2==0 then return end
	g1:Merge(g2)
	Duel.SendtoHand(g1,nil,REASON_EFFECT)
	Duel.ConfirmCards(1-tp,g1)

	--추가효과: 마력카운터 5개 제거 후 파괴
	if Duel.IsExistingMatchingCard(Card.IsCanRemoveCounter,tp,LOCATION_ONFIELD,0,1,nil,tp,0x1,5,REASON_EFFECT)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		if Duel.RemoveCounter(tp,1,0,0x1,5,REASON_EFFECT)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
			if #g>0 then
				Duel.Destroy(g,REASON_EFFECT)
			end
		end
	end
end
