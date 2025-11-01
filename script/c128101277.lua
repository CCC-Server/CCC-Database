--Link Rokket Support Monster
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon procedure (2 DARK Dragon monsters, including 1 Rokket)
	Link.AddProcedure(c,s.matfilter,2,2)
	c:EnableReviveLimit()

	-- Effect ①: When Link Summoned or sent to GY, add 1 "Rokket" monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon_grave)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.thcon_link)
	c:RegisterEffect(e2)

	-- Effect ②: If treated as Equip Spell, return to Extra and Special Summon Link-2 DARK Dragon
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.eqcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_ROKKET}

-----------------------------------------------------
-- Material Filter: DARK Dragon + includes Rokket
-----------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,lc,sumtype,tp) and c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp)
end

-----------------------------------------------------
-- Effect ①: Add 1 Rokket from Deck to Hand
-----------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_ROKKET) and c:IsAbleToHand()
end

function s.thcon_link(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thcon_grave(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
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

-----------------------------------------------------
-- Effect ②: If this card is treated as Equip Spell
-----------------------------------------------------
function s.eqcon(e)
	return e:GetHandler():IsType(TYPE_EQUIP)
end

function s.spfilter(c,e,tp)
	return c:IsRace(RACE_DRAGON) and c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsType(TYPE_LINK) and c:GetLink()==2
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	if Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT) == 0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=g:GetFirst()
	if sc then
		Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
