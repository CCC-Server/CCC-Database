-- 운마물-생명의 구름
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Continuous Effect (Summon Success)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	-- Continuous Effect (Special Summon Success)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- List the "운마물" series
	s.listed_series={0x18}
end

-- Search filter (for "운마물" monsters)
function s.thfilter(c)
	return c:IsAbleToHand() and c:IsSetCard(0x18) and c:IsMonster()
end

-- Activate function (search "운마물" monster)
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- Continuous Effect Operation (Add Counter when "운마물" is Summoned)
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(aux.FaceupFilter(Card.IsSetCard,0x18),1,nil) then
		e:GetHandler():AddCounter(0x1019,1)
	end
end
