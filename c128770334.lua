local s,id=GetID()
function s.initial_effect(c)

	-----------------------------------------------------------
	-- ① 소환 성공 시 네메시스 몬스터 파괴 후 마/함 세트
	-----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-----------------------------------------------------------
	-- ② 네메시스 디스트로이돌 융합 몬스터 Contact Fusion
	-----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON + CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.fuscon)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------------
-- ① 파괴할 네메시스 몬스터
-----------------------------------------------------------
function s.desfilter1(c)
	return c:IsSetCard(0x765) and c:IsMonster() and c:IsDestructable()
end

-- 세트할 마/함
function s.stfilter(c)
	return c:IsSetCard(0x765) and c:IsSpellTrap() and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.desfilter1,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_MZONE)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local dg=Duel.SelectMatchingCard(tp,s.desfilter1,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil)
	if #dg>0 and Duel.Destroy(dg,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local sg=Duel.SelectMatchingCard(tp,s.stfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			Duel.SSet(tp,sg)
		end
	end
end

-----------------------------------------------------------
-- ② Contact Fusion 조건
-----------------------------------------------------------
function s.fuscon(e,tp)
	return Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
end

-- 융합 소재 후보: 패/자신 필드/상대 필드 특소몬스터
function s.matfilter(c)
	return c:IsMonster() and c:IsDestructable() and c:IsAbleToGrave()
end

function s.rfilter(c,tp,mg)
	return c:IsSetCard(0x765) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(nil,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,tp)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- 소재 풀 생성
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,LOCATION_MZONE,nil)
	-- 상대 몬스터는 "특수 소환된 몬스터"만
	mg=mg:Filter(function(c)
		if c:IsControler(1-tp) then
			return c:IsSummonType(SUMMON_TYPE_SPECIAL)
		end
		return true
	end,nil)

	-- 반드시 이 카드를 포함해야 함
	if not mg:IsContains(c) then
		mg:AddCard(c)
	end

	if chk==0 then
		return Duel.IsExistingMatchingCard(s.rfilter,tp,LOCATION_EXTRA,0,1,nil,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_MZONE)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,LOCATION_MZONE,nil)
	mg=mg:Filter(function(c)
		if c:IsControler(1-tp) then return c:IsSummonType(SUMMON_TYPE_SPECIAL) end
		return true
	end,nil)

	if not mg:IsContains(c) then mg:AddCard(c) end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.rfilter,tp,LOCATION_EXTRA,0,1,1,nil,tp,mg)
	local sc=sg:GetFirst()
	if not sc then return end

	-- 해당 융합 몬스터를 위한 정확한 소재 선택
	local mat=Duel.SelectFusionMaterial(tp,sc,mg,c,tp)
	if #mat==0 then return end

	Duel.HintSelection(mat)

	-- Contact Fusion 방식: 파괴 후 묘지로 보내 재료 처리
	if Duel.Destroy(mat,REASON_EFFECT+REASON_MATERIAL)==0 then return end

	sc:SetMaterial(mat)
	Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	sc:CompleteProcedure()
end
