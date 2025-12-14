local s,id=GetID()
function s.initial_effect(c)
	-- 카드 발동 + ① 효과
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e0:SetTarget(s.fusion1_tg)
	e0:SetOperation(s.fusion1_op)
	c:RegisterEffect(e0)

	-- ② 묘지에서 발동
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCost(s.fusion2_cost)
	e2:SetTarget(s.fusion2_tg)
	e2:SetOperation(s.fusion2_op)
	c:RegisterEffect(e2)
end

------------------------------------------------------------------
-- 🔒 융합 이외의 엑스트라 덱 특수 소환 제한
function s.fusion_limit(c,tp)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.splimit(e,c)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_FUSION)
end

------------------------------------------------------------------
-- 공통: 데스완구 융합 몬스터 필터
function s.fusion_target_filter(c,e,tp,mg)
	return c:IsSetCard(0xad) and c:IsType(TYPE_FUSION)
		and c:CheckFusionMaterial(mg,nil,tp)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

------------------------------------------------------------------
-- ① 발동 시 융합 처리 (패/덱/필드)
function s.matfilter1(c)
	return c:IsMonster() and c:IsAbleToGrave()
end
function s.fusion1_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK,0,nil)
		return Duel.IsExistingMatchingCard(s.fusion_target_filter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusion1_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	s.fusion_limit(c,tp)

	local mg=Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK,0,nil)
	local sg=Duel.GetMatchingGroup(s.fusion_target_filter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
	if #sg==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=sg:Select(tp,1,1,nil):GetFirst()
	if not tc then return end

	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
	if not mat or #mat==0 then return end

	tc:SetMaterial(mat)
	Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end

------------------------------------------------------------------
-- ② 묘지 발동 코스트
function s.fusion2_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return aux.exccon(e) end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- 묘지/제외에서 소재
function s.matfilter2(c)
	return c:IsMonster() and c:IsAbleToDeck()
end
function s.fusion2_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter2,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		return Duel.IsExistingMatchingCard(s.fusion_target_filter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusion2_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	s.fusion_limit(c,tp)

	local mg=Duel.GetMatchingGroup(s.matfilter2,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	local sg=Duel.GetMatchingGroup(s.fusion_target_filter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
	if #sg==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=sg:Select(tp,1,1,nil):GetFirst()
	if not tc then return end

	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
	if not mat or #mat==0 then return end

	tc:SetMaterial(mat)
	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end


