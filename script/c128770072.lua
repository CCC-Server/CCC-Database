-- U.K-속공융합 (속공 마법)
local s,id=GetID()
function s.initial_effect(c)
	-- 속공 마법 발동 (배틀 페이즈 중에만 가능)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(TIMING_BATTLE_PHASE,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.bpcon)
	e1:SetTarget(s.fustg1)
	e1:SetOperation(s.fusop1)
	c:RegisterEffect(e1)
	
	-- 묘지에서 제외하고 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.bpcon)
	e2:SetCost(s.fuscost2)
	e2:SetTarget(s.fustg2)
	e2:SetOperation(s.fusop2)
	c:RegisterEffect(e2)
end

-- 배틀 페이즈에서만 발동 가능
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

-- 융합 소환할 몬스터 선택 (패/필드에서만 소재 사용 가능)
function s.fustg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,nil)
			and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- 융합 소환 실행 (패/필드에서만 소재 사용 가능, 묘지로 보냄)
function s.fusop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,aux.FilterBoolFunction(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=sg:GetFirst()
	if not tc then return end
	
	local mg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=mg:Select(tp,tc.min_material_count,tc.max_material_count,nil)
	if not mat or #mat==0 then return end
	
	tc:SetMaterial(mat)
	Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end

-- 묘지에서 발동할 때의 비용 (패/덱에서 U.K 몬스터 릴리스 후, 이 카드 제외)
function s.fuscost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.fusrelease,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
			and e:GetHandler():IsAbleToRemoveAsCost()
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.fusrelease,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if g:GetFirst():IsLocation(LOCATION_DECK) then
			Duel.SendtoGrave(g,REASON_COST+REASON_RELEASE)
			Duel.RaiseSingleEvent(g:GetFirst(),EVENT_RELEASE,e,REASON_COST,tp,tp,0)
		else
			Duel.Release(g,REASON_COST)
		end
	end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- 융합 소재 필터 (U.K 몬스터만 가능)
function s.fusfilter(c)
	return c:IsSetCard(0x42d) and c:IsCanBeFusionMaterial()
end

-- 패/덱에서 릴리스할 U.K 몬스터 필터 (마법/함정 제외)
function s.fusrelease(c)
	return c:IsSetCard(0x42d) and c:IsType(TYPE_MONSTER)
end

-- 묘지에서 발동 시 (묘지에서만 소재 사용 가능)
function s.fustg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,nil)
			and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- 묘지에서 발동할 경우 (묘지에서만 소재 사용 가능, 제외됨)
function s.fusop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,aux.FilterBoolFunction(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=sg:GetFirst()
	if not tc then return end
	
	local mg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_GRAVE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=mg:Select(tp,tc.min_material_count,tc.max_material_count,nil)
	if not mat or #mat==0 then return end
	
	tc:SetMaterial(mat)
	Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end