local s,id=GetID()
function s.initial_effect(c)
	-- (1) Fusion Summon using Dragon Gemini monsters from hand/field
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)
	-- (2) Extra Normal Summon (from GY)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(aux.bfgcost) -- Banish self from GY
	e2:SetOperation(s.sumop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------------
-- (1) Fusion Summon (only Dragon Gemini as materials)
-----------------------------------------------------------
function s.matfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsCanBeFusionMaterial()
end
function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,tp)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
		return #mg>0 and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	local sg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
	if #mg==0 or #sg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=sg:Select(tp,1,1,nil)
	local tc=tg:GetFirst()
	if not tc then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
	tc:SetMaterial(mat)
	Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end

-----------------------------------------------------------
-- (2) Extra Normal Summon for Dragon Gemini
-----------------------------------------------------------
function s.sumfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(s.sumfilter))
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
