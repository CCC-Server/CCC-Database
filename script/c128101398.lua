--Mist Valley Thunder Roc
--안개 골짜기의 뇌조
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(aux.FilterBoolFunction(Card.IsSetCard,0x37)),1,99)
	c:EnableReviveLimit()
	--Effect 1: Main Phase Quick (Send from Deck OR Hand -> SS)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetCost(s.spcost1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	--Effect 2: Bounce Trigger
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.spcon2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end
s.listed_series={0x37}

-- (1) Condition: Main Phase
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

-- Filters for Validity Check
-- Filter A: Valid SS target in GY (different name from 'code')
function s.spfilter_gy_valid(c,e,tp,code)
	return c:IsSetCard(0x37) and c:IsType(TYPE_MONSTER) and not c:IsCode(code) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Filter B: Cost (Deck) - Must have a valid target in GY that is NOT the card being sent
function s.cfilter_deck_valid(c,tp,e)
	return c:IsSetCard(0x37) and c:IsType(TYPE_MONSTER) and c:IsLevelBelow(4) and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(s.spfilter_gy_valid,tp,LOCATION_GRAVE,0,1,nil,e,tp,c:GetCode())
end

-- Filter C: Cost (Hand) - Must have a valid target in GY that is NOT the card being sent
function s.cfilter_hand_valid(c,tp,e)
	return c:IsSetCard(0x37) and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(s.spfilter_gy_valid,tp,LOCATION_GRAVE,0,1,nil,e,tp,c:GetCode())
end

-- (1) Cost
function s.spcost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.cfilter_deck_valid,tp,LOCATION_DECK,0,1,nil,tp,e)
	local b2=Duel.IsExistingMatchingCard(s.cfilter_hand_valid,tp,LOCATION_HAND,0,1,nil,tp,e)
	if chk==0 then return (b1 or b2) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3)) -- 0: Send from Deck, 1: Send from Hand
	elseif b1 then
		op=0
		Duel.SelectOption(tp,aux.Stringid(id,2))
	else
		op=1
		Duel.SelectOption(tp,aux.Stringid(id,3))
	end
	
	e:SetLabel(op)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=nil
	if op==0 then
		g=Duel.SelectMatchingCard(tp,s.cfilter_deck_valid,tp,LOCATION_DECK,0,1,1,nil,tp,e)
	else
		g=Duel.SelectMatchingCard(tp,s.cfilter_hand_valid,tp,LOCATION_HAND,0,1,1,nil,tp,e)
	end
	Duel.SendtoGrave(g,REASON_COST)
	e:SetLabelObject(g:GetFirst()) -- Remember the sent card
end

-- (1) Target
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- Validity checked in Cost
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- (1) Operation
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local sent_c=e:GetLabelObject()
	local op=e:GetLabel() -- 0: Deck, 1: Hand
	local code=sent_c:GetCode()
	
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	-- Part 1: Special Summon different name (Mandatory part of effect)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter_gy_valid),tp,LOCATION_GRAVE,0,1,1,nil,e,tp,code)
	if #g>0 then
		if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
			-- Part 2: Bonus SS if Hand was used (Optional)
			if op==1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				local g2=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter_bonus),tp,LOCATION_GRAVE,0,nil,e,tp)
				if #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
					Duel.BreakEffect()
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
					local sg=g2:Select(tp,1,1,nil)
					Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
				end
			end
		end
	end
end

function s.spfilter_bonus(c,e,tp)
	return c:IsSetCard(0x37) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- (2) Condition: Card returns to hand
function s.cfilter2(c)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter2,1,nil)
end

-- (2) Target
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter_hand,tp,LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.spfilter_hand(c,e,tp)
	return c:IsSetCard(0x37) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- (2) Operation
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter_hand,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end