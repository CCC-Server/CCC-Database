local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드명의 ①, ②, ③의 효과는 각각 1턴에 1번 밖에 사용할 수 없다.
	
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
	e2:SetCountLimit(1,id+1) -- ② 1턴에 1번
	e2:SetCondition(s.xyz_quick_con)
	e2:SetTarget(s.xyz_quick_tg)
	e2:SetOperation(s.xyz_quick_op)
	c:RegisterEffect(e2)

	-- ③ Xyz Summon on attack declaration (필드 몬스터 전체 사용 엑시즈 소환)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,id+2) -- ③ 1턴에 1번
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
function s.xyzcheckfilter(c, e, tp)
	-- c: 엑스트라 덱의 엑시즈 몬스터, e: 발동 효과, tp: 플레이어
	
	local c_handler = e:GetHandler()
	
	-- 핸들러가 필드에 없거나 뒷면 표시이면 소환 불가
	if not c_handler:IsRelateToEffect(e) or c_handler:IsFacedown() then return false end
	
	-- 엑시즈 몬스터 'c'가 '수왕권사' 몬스터인지 확인 
	if not c:IsSetCard(0x770) or not c:IsType(TYPE_XYZ) then return false end
	
	-- 엑시즈 몬스터 'c'가 c_handler를 소재로 사용할 수 있는지 확인
	if not c:IsCanBeXyzMaterial(c_handler) then return false end

	local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, 0, nil)
	local max_mat = math.min(#g, 5) -- 필드의 몬스터 수 (최대 5장으로 제한)
	
	-- 최소 1장(이 카드 자신) 이상으로 소환 가능한지 IsXyzSummonable로 확인
	-- MustMaterialCount 호출 제거 (크래시 방지)
	return c:IsXyzSummonable(g, 1, max_mat)
end


function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 소환 가능한 "수왕권사" 엑시즈 몬스터가 있는지 확인
		return Duel.IsExistingMatchingCard(s.xyzcheckfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp)
	end
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 발동한 몬스터가 여전히 필드에 앞면 표시로 존재하고, 공격 중인지 확인
	if not c:IsRelateToEffect(e) or c:IsFacedown() or Duel.GetAttacker()~=c then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	-- 소환 가능한 엑시즈 몬스터를 선택
	local sc=Duel.SelectMatchingCard(tp,s.xyzcheckfilter,tp,LOCATION_EXTRA,0,1,1,nil, e, tp):GetFirst()
	if not sc then return end

	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	
	-- c는 필수 소재로 지정
	local mat = Group.FromCards(c)

	-- sc를 엑시즈 소재로 할 수 있는 몬스터만 대상으로 설정 (c 제외)
	local non_c_mg = mg:Clone()
	non_c_mg:RemoveCard(c)
	local filter = function(tc) return sc:IsCanBeXyzMaterial(tc) end
	local valid_others = non_c_mg:Filter(filter, nil)
	
	local max_mat_available = math.min(#mg, 5) 
	local max_others = math.max(0, max_mat_available - 1) 

	-- 선택 UI를 띄워 0장~max_others장 선택 (c를 제외한 나머지)
	if max_others > 0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		-- 최소 선택 강제 없이 0장에서 최대치까지 선택
		local mat_others = valid_others:Select(tp, 0, max_others, nil)
		mat:Merge(mat_others)
	end
	
	-- Xyz Summon Procedure
	Duel.Overlay(sc,mat)
	sc:EnableReviveLimit()
	Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
	sc:CompleteProcedure()

	Duel.ChangeAttackTarget(nil)
end