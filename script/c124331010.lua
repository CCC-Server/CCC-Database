--동물귀무녀 카구라
--けもみみこかぐら
--Mimiko Kagura
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Fusion.CreateSummonEff({handler=c,fusfilter=s.ffilter,matfilter=Card.IsAbleToDeck,
									 extrafil=s.fextra,extraop=Fusion.ShuffleMaterial,extratg=s.extrtarget})
	e1:SetHintTiming(0,TIMING_END_PHASE)
	c:RegisterEffect(e1)
	--Activate 1 of these effects
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.effcon)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

--Part of "Mimiko" archetype
s.listed_series={0xda0}

function s.ffilter(c)
	return c:IsSetCard(0xda0)
end
function s.fextra(e,tp,mg,sumtype)
	return Duel.GetMatchingGroup(aux.NecroValleyFilter(Fusion.IsMonsterFilter(Card.IsAbleToDeck)),tp,LOCATION_GRAVE,0,nil),s.fcheck
end

function s.extrtarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE)
end

function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xda0),tp,LOCATION_MZONE,0,1,nil)
end

function s.tdfilter(c)
	return c:IsRace(RACE_BEAST) and c:IsAbleToDeck()
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=c:IsAbleToHand()
	local b2=c:IsAbleToDeck()
		 and Duel.IsPlayerCanDraw(tp)
		 and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,2)},
		{b2,aux.Stringid(id,3)})
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(CATEGORY_TOHAND)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
	else
		e:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,tp,0)
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,2,tp,1)
	end
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if e:GetLabel()==1 then
		--Add this card to your hand
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
		else
   if c:IsRelateToEffect(e) and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
		Duel.SendtoDeck(c+g,nil,0,REASON_EFFECT)
		Duel.ShuffleDeck(tp)
		Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end