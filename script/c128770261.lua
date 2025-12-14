--Dual Dragon Synthesis (듀얼 드래곤 합성)
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------------------------
	--① 발동 효과 (파괴)
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- 이 카드명은 1턴에 1장만
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	--------------------------------------------------
	--② 묘지 제외 융합 소환
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost) -- 묘지에서 제외
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
--①: 파괴 효과
--------------------------------------------------
function s.lvfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsLevelAbove(3)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.lvfilter,tp,LOCATION_HAND,0,1,nil)
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.lvfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	-- 레벨 2 내리기 (일시적 효과)
	Duel.ConfirmCards(1-tp,tc)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-2)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	tc:RegisterEffect(e1)

	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local dg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #dg>0 then
		Duel.HintSelection(dg)
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

--------------------------------------------------
--②: 융합 소환 효과
--------------------------------------------------
function s.matfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsAbleToDeck()
end
function s.fusfilter(c,e,tp)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,0,nil)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local fus=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if not fus then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local mat=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,0,2,63,nil)
	if #mat==0 then return end
	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.BreakEffect()
	if Duel.SpecialSummon(fus,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		fus:CompleteProcedure()
	end
end
