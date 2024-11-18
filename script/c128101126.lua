-- 운마물 이클립스
-- 魔神王の禁断契約書
-- Forbidden Dark Contract with the Swamp King
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- Effect 1: Fusion Summon
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_FUSION_SUMMON+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)

	-- Effect 2: Return to Deck and destroy
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)

end

-- Special Summon filter
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x18) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Fusion Summon target
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil,tp)
			and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- Fusion Summon operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_HAND+LOCATION_MZONE,0,nil,tp)

	-- Include opponent's monsters with Fog Counters as additional materials
	local fg=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local fgc=fg:Filter(function(c) return c:GetCounter(0x1019) > 0 end, nil)  -- Only include monsters with Fog Counters
	if #fgc>0 then
		mg:Merge(fgc)  -- Add opponent's monsters with Fog Counters to materials
	end

	-- Fusion Summon
	local sg=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local fusion=sg:Select(tp,1,1,nil):GetFirst()
		if fusion then
			local mat=Duel.SelectFusionMaterial(tp,fusion,mg,tp)
			fusion:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.SpecialSummon(fusion,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			fusion:CompleteProcedure()
		end
	end
end

-- Filter for Fusion materials (Only "운마물" monsters or monsters with Fog Counters)
function s.filter1(c,tp)
	return c:IsCanBeFusionMaterial() and (c:IsSetCard(0x18) or (c:IsFaceup() and c:GetCounter(0x1019) > 0))  -- Add any monster with Fog Counters as valid materials
end

function s.filter2(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x18) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,tp)
end
function s.tdfilter(c)
	return c:IsSetCard(0x18) and c:IsFaceup() and c:IsAbleToDeck() and not c:IsCode(id)
end
function s.crystsyncfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x18) and c:IsType(TYPE_FUSION) and c:IsType(TYPE_LINK)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local exc=not c:IsStatus(STATUS_EFFECT_ENABLED) and c or nil
	if chkc then return chkc:IsOnField() and chkc:IsFaceup() and (not exc or chkc~=exc) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,exc)
		and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) end
	local ct=Duel.IsExistingMatchingCard(s.crystsyncfilter,tp,LOCATION_MZONE,0,1,nil) and 2 or 1
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,tp,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.tdfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	if #g==0 then return end
	Duel.HintSelection(g)
	if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	local tg=Duel.GetTargetCards(e)
	if #tg>0 then
		Duel.Destroy(tg,REASON_EFFECT)
	end
end