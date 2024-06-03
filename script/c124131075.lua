--RUM-디 오션즈 원
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	Duel.AddCustomActivityCounter(id,ACTIVITY_SPSUMMON,s.counterfilter)
end
function s.counterfilter(c)
	return (c:IsRankAbove(4) and c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_XYZ)) or c:GetSummonLocation()~=LOCATION_EXTRA
end
function s.filter1(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_WATER) and (c:IsRace(RACE_WINGEDBEAST) or c:IsRace(RACE_FAIRY) or c:IsRace(RACE_WARRIOR))
		and c:IsType(TYPE_XYZ) and (c:IsRank(4) or c:IsRank(5)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end

function s.filter2(c,e,tp,mc)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(mc:GetRace()) and c:IsRank(mc:GetRank()+1) and c:IsAttribute(ATTRIBUTE_WATER)
		and mc:IsCanBeXyzMaterial(c,tp) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,1),nil)
	--lizard check
	aux.addTempLizardCheck(e:GetHandler(),tp,s.lizfilter)
	end
	function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:IsRankAbove(4) and c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_XYZ)) and c:IsLocation(LOCATION_EXTRA)
	end
	function s.lizfilter(e,c)
	return not (c:IsRankAbove(4) and c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_XYZ))
	end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanSpecialSummonCount(tp,2)
		and Duel.GetLocationCountFromEx(tp,tp,nil,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,LOCATION_MZONE)<1 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g1=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc1=g1:GetFirst()
	if tc1 and Duel.SpecialSummon(tc1,0,tp,tp,false,false,POS_FACEUP)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g2=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc1)
		local tc2=g2:GetFirst()
		if tc2 then
			tc2:SetMaterial(g1)
			Duel.Overlay(tc2,g1)
			Duel.SpecialSummon(tc2,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
			tc2:CompleteProcedure()
		end
	end
end