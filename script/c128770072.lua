-- U.K-속공융합
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 배틀 페이즈 중 융합 소환
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCondition(s.fuscon1)
	e1:SetTarget(s.fustg1)
	e1:SetOperation(s.fusop1)
	c:RegisterEffect(e1)

	-- ②: 전투 실행 시 묘지에서 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.fuscon2)
	e2:SetCost(s.fuscost2)
	e2:SetTarget(s.fustg2)
	e2:SetOperation(s.fusop2)
	c:RegisterEffect(e2)
end

-- ① 효과 조건: 배틀 페이즈 중
function s.fuscon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

-- ① 효과: 융합 소재 필터 (패 / 필드)
function s.fusfilter1(c)
	return c:IsAbleToGrave() and c:IsCanBeFusionMaterial()
end

-- ① 효과: 융합 소환할 몬스터 선택
function s.fustg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(Fusion.IsMonsterFilter(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.fusfilter1,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ① 효과: 융합 소환 실행
function s.fusop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,Fusion.IsMonsterFilter(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=sg:GetFirst()
	if not tc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=Duel.SelectFusionMaterial(tp,tc,Duel.GetMatchingGroup(s.fusfilter1,tp,LOCATION_HAND+LOCATION_MZONE,0,nil))

	if #mat>0 then
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end

-- ② 효과 조건: 자신의 "U.K" 몬스터가 공격 선언할 때
function s.fuscon2(e,tp,eg,ep,ev,re,r,rp)
	local ac=Duel.GetAttacker()
	return ac and ac:IsControler(tp) and ac:IsSetCard(0x42d)
end

-- ② 효과 비용: 묘지의 이 카드를 제외하고, 패 / 덱에서 "U.K" 몬스터 1장을 릴리스
function s.fuscost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsReleasable,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,Card.IsReleasable,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	Duel.Release(g,REASON_COST)
end

-- ② 효과: 묘지에서 사용할 융합 소재 확인
function s.fustg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Fusion.IsMonsterFilter(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(Card.IsCanBeFusionMaterial,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ② 효과: 묘지에서 융합 소재 사용하여 융합 소환 실행
function s.fusop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,Fusion.IsMonsterFilter(Card.IsSetCard,0x42d),tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=sg:GetFirst()
	if not tc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=Duel.SelectFusionMaterial(tp,tc,Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_GRAVE,0,nil))

	if #mat>0 then
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end