local s,id=GetID()
function s.initial_effect(c)
	-- ① Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- ① 1턴에 1번
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- **② Quick Xyz Summon (대상 지정 엑시즈 소환)**
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O) -- 유발 즉시 효과
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_MAIN_END+TIMING_BATTLE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1}) -- ② 1턴에 1번
	e2:SetCondition(s.xyz_quick_con)
	e2:SetTarget(s.xyz_quick_tg)
	e2:SetOperation(s.xyz_quick_op)
	c:RegisterEffect(e2)

	-- ③ Xyz Summon on attack declaration
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.xyztg)
	e3:SetOperation(s.xyzop)
	c:RegisterEffect(e3)
end

-- =========================
-- ① Special Summon condition
-- =========================
function s.spfilter(c)
	-- "수왕권사"가 아닌 몬스터를 필터링 (0x770은 "수왕권사"의 SetCard ID라고 가정)
	return not c:IsSetCard(0x770)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- 필드에 몬스터가 없거나, "수왕권사"가 아닌 몬스터가 0장일 경우 (즉, "수왕권사" 몬스터 뿐일 경우)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and
		not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- =========================
-- ② Quick Xyz Summon (대상 지정 엑시즈 소환)
-- (* 차후 수정 및 검토 필요)
-- =========================
function s.xyz_quick_con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() or Duel.IsBattlePhase()
end

-- 필터: 소재로 지정할 수 있는 "수왕권사" 몬스터 1장
function s.xyz_quick_mat_filter(c)
	return c:IsFaceup() and c:IsSetCard(0x770)
end

-- 필터: 이 카드를 소재로 하여 소환 가능한 "수왕권사" 엑시즈 몬스터
function s.xyz_quick_xyz_filter(c, mat)
	-- mat: 소재로 지정된 몬스터 그룹 (1장)
	-- c: 엑스트라 덱의 엑시즈 몬스터
	if not c:IsSetCard(0x770) or not c:IsType(TYPE_XYZ) then return false end
	
	-- 이 카드가 소재가 될 수 있는지
	if not c:IsCanBeXyzMaterial(mat:GetFirst()) then return false end

	-- 정확히 1장의 소재로 소환 가능한지 확인 (min=1, max=1)
	return c:IsXyzSummonable(mat, 1, 1)
end

function s.xyz_quick_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mat_g = Duel.GetMatchingGroup(s.xyz_quick_mat_filter, tp, LOCATION_MZONE, 0, nil)
		if #mat_g == 0 then return false end

		local res = false
		-- 필드의 모든 "수왕권사" 몬스터를 소재로 하여 소환 가능한 엑시즈 몬스터가 있는지 확인
		for tc in aux.iterate(mat_g) do
			local mat = Group.FromCards(tc)
			if Duel.IsExistingMatchingCard(s.xyz_quick_xyz_filter, tp, LOCATION_EXTRA, 0, 1, nil, mat) then
				res = true
				break
			end
		end
		return res
	end
	
	-- Target: 1 "수왕권사" monster on your field.
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.xyz_quick_mat_filter, tp, LOCATION_MZONE, 0, 1, 1, nil)
end

function s.xyz_quick_op(e,tp,eg,ep,ev,re,r,rp)
	local tc = Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	
	local mat = Group.FromCards(tc)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	-- 소환 가능한 엑시즈 몬스터를 선택
	local sc = Duel.SelectMatchingCard(tp, s.xyz_quick_xyz_filter, tp, LOCATION_EXTRA, 0, 1, 1, nil, mat):GetFirst()
	
	if sc then
		sc:SetMaterial(mat)
		Duel.Overlay(sc, mat)
		Duel.SpecialSummon(sc, SUMMON_TYPE_XYZ, tp, tp, false, false, POS_FACEUP)
		sc:CompleteProcedure()
	end
end

-- =========================
-- ③ Xyz Summon on attack (필드 몬스터 전체 사용 엑시즈 소환)
-- =========================
function s.xyzfilter(c)
	return c:IsSetCard(0x770) and c:IsXyzSummonable()
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=g:Select(tp,1,1,nil)
		Duel.XyzSummon(tp,tg:GetFirst())
	end
end
