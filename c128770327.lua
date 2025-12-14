local s,id=GetID()
function s.initial_effect(c)
	-- Activate (Fusion Summon using custom material range)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Filter: 네메시스 아티팩트 몬스터
function s.matfilter(c,e,tp)
	-- 필드/패에 있거나 마/함 존에 있는 카드 중 원래 몬스터 카드인 경우만 허용
	if c:IsLocation(LOCATION_SZONE) and (c:GetOriginalType() & TYPE_MONSTER == 0) then return false end
	return c:IsSetCard(0x764) and c:IsCanBeFusionMaterial() and not c:IsImmuneToEffect(e)
end

-- 네메시스 아티팩트 융합 몬스터 필터
function s.fusfilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x764) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,f,chkf)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		-- 패 + 필드 + SZONE (마/함 존) 전체에서 체크
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_SZONE,0,nil,e,tp)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_SZONE,0,nil,e,tp)
	local sg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,chkf)
	if #sg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=sg:Select(tp,1,1,nil)
	local tc=tg:GetFirst()
	if tc then
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
		if not mat or #mat==0 then return end
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end
