--유네티스 섀도우 슬립
local s,id=GetID()
function s.initial_effect(c)
	--①: 자신 몬스터 바운스 후 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--②: 묘지 제외 후 3장 덱으로 되돌리고 드로우
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc80}

-- [효과 ①]
function s.thfilter(c)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.sumfilter(c)
	return c:IsSetCard(0xc80) and c:IsSummonable(true,nil)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local g=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #g>0 then
			Duel.Summon(tp,g:GetFirst(),true,nil)
		end
	end
end

-- [효과 ②]
function s.tdfilter(c)
	return c:IsSetCard(0xc80) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToDeck()
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1)
		and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,e:GetHandler()) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
	if #g>0 then
		Duel.HintSelection(g)
		if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
			local og=Duel.GetOperatedGroup()
			if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
				if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then Duel.ShuffleDeck(tp) end
				Duel.BreakEffect()
				Duel.Draw(tp,1,REASON_EFFECT)
			end
		end
	end
end