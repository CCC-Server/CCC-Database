--드래곤블러드 석세서
--龍血の継承者
--Dragonblood Succesor
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Tribute 1 "DragonBlood" monster, and if you do, Special Summon this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCountLimit(1,id)
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--search
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--Return this card and Special Summon another "Dragonblood" monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.sdtg)
	e3:SetOperation(s.sdop)
	c:RegisterEffect(e3)
end

--Part of "Dragonblood" archetype
s.listed_series={0xda3}

--Special summon itself
function s.tributefilter(c,e,tp)
	return (c:IsType(TYPE_RITUAL) or c:IsSetCard(0xda3)) and c:IsAbleToGrave()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.tributefilter,tp,LOCATION_ONFIELD|LOCATION_HAND,0,1,nil,e,tp)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,true) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=Duel.SelectMatchingCard(tp,s.tributefilter,tp,LOCATION_ONFIELD|LOCATION_HAND,0,1,1,nil,e,tp)
	if #rg==0 or Duel.SendtoGrave(rg,REASON_RELEASE+REASON_EFFECT)==0 then return end
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,true,true,POS_FACEUP)>0 then
		c:CompleteProcedure()   
	end
end

--search
function s.thfilter(c)
	return c:IsSetCard(0xda3) and c:IsAbleToHand() and not c:IsCode(id)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,nil)
		return g:GetClassCount(Card.GetCode)>=1
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,nil)
	if g:GetClassCount(Card.GetCode)>=1 then
		local sg=aux.SelectUnselectGroup(g,e,tp,1,2,aux.dncheck,1,tp,HINTMSG_ATOHAND)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

--Return this card and Special Summon another "Dragonblood" monster
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_RITUAL) and c:IsSetCard(0xda3) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false,POS_FACEUP)
end

function s.sdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1 and c:IsAbleToHand() and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.sdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)~=0 and c:IsLocation(LOCATION_HAND) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,SUMMON_TYPE_RITUAL,tp,tp,false,false,POS_FACEUP)
		end
	end
end
