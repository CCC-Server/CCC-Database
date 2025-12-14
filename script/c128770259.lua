--Orca of the Great Sea (대해의 오르카)
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------------------------
	--① 토큰 생성
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.tktg)
	e1:SetOperation(s.tkop)
	c:RegisterEffect(e1)

	--------------------------------------------------
	--② 묘지 제외 융합 소환
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
--①: 토큰 생성
--------------------------------------------------
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,128770343,0,TYPES_TOKEN,1600,1200,4,RACE_DRAGON,ATTRIBUTE_WATER)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,128770343,0,TYPES_TOKEN,1600,1200,4,RACE_DRAGON,ATTRIBUTE_WATER) then return end
	local token=Duel.CreateToken(tp,128770343)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)

	--릴리스 제한 (드래곤족 듀얼 몬스터 어드밴스/융합 소재 이외 불가)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UNRELEASABLE_SUM)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.relval)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	token:RegisterEffect(e1,true)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	token:RegisterEffect(e2,true)
end
function s.relval(e,c)
	return not (c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI))
end

--------------------------------------------------
--②: 묘지 제외 후 융합 소환
--------------------------------------------------
function s.matfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsAbleToRemove()
end
function s.fusfilter(c,e,tp)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local rg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and #rg>=2
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,2,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local rg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil)
	if #rg<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local mat=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_GRAVE,0,2,63,nil)
	if #mat==0 then return end
	if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT)==0 then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local fus=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if fus then
		Duel.SpecialSummon(fus,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		fus:CompleteProcedure()
	end
end
