--마도식자 바테르
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--엑시즈 소환 : 마법사족 레벨 3 몬스터 × 2
	--또는 패 / 필드(앞면 표시)의 마법 카드 1장을 제외하고, 자신 필드의 "마도서사 바테르" 위에 겹쳐 엑시즈 소환
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),3,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
	--①: 자신의 "마도서" 카드의 효과의 발동에 대하여 상대는 효과를 발동할 수 없다
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetOperation(s.chainop)
	c:RegisterEffect(e1)
	--②: 소재 1개 제거 + 덱의 "마도서" 카드 2장까지 묘지로 → 묘지 / 제외 상태의 "마도서" 카드 1장을 패에
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_names={14824019}
s.listed_series={0x106e}
--타협 소환
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsCode(14824019)
end
function s.xyzcfilter(c)
	return c:IsSpell() and (c:IsLocation(LOCATION_HAND) or c:IsFaceup()) and c:IsAbleToRemoveAsCost()
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.xyzcfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.xyzcfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	return true
end
--①
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if ep==tp and re:GetHandler():IsSetCard(0x106e) then
		Duel.SetChainLimit(s.chainlm)
	end
end
function s.chainlm(e,rp,tp)
	return tp==rp
end
--②
function s.tgfilter(c)
	return c:IsSetCard(0x106e) and c:IsAbleToGraveAsCost()
end
function s.thfilter(c)
	return c:IsSetCard(0x106e) and (c:IsFaceup() or not c:IsLocation(LOCATION_REMOVED)) and c:IsAbleToHand()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,2,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
