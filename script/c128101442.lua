--종이 비행기 합체
local s,id=GetID()
function s.initial_effect(c)
	-- "Paper Plane" 카드군
	s.listed_series={0xc53}

	--------------------------------
	-- ① 융합 소환
	-- (이 카드명의 ① 효과는 1턴에 1번)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) -- ① 텍스트
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,0}) -- ① 하드 OPT
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② GY에서 발동 / 드로우
	-- (이 카드명의 ② 효과는 1턴에 1번)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1)) -- ② 텍스트
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1}) -- ② 하드 OPT
	e2:SetCondition(s.drcon)
	e2:SetCost(s.drcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

--------------------------------
-- 공통 필터들
--------------------------------
-- 패/필드에서 사용 가능한 "Paper Plane" 몬스터 (기본 융합 소재)
function s.fieldmatfilter(c,e)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER)
		and not c:IsImmuneToEffect(e)
end

-- GY에서 융합 소재로 사용할 수 있는 "Paper Plane" 몬스터
function s.gymatfilter(c)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER)
		and c:IsLocation(LOCATION_GRAVE) and c:IsAbleToDeck()
end

-- 필드에 유니온 몬스터를 컨트롤하는가?
function s.unionfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_UNION)
end
function s.union_present(tp)
	return Duel.IsExistingMatchingCard(s.unionfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 엑덱의 "Paper Plane" 융합 몬스터 중,
-- 주어진 소재 그룹(mg)으로 실제 융합 가능한 것만 필터
function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,chkf)
end

--------------------------------
-- ① 융합 소환 타깃
--------------------------------
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 몬스터 존에 빈 자리가 없으면 필드 몬스터 1장은 반드시 써야 함
	local chkf=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and PLAYER_NONE or tp

	-- 기본 융합 소재: 패 + 필드의 "Paper Plane" 몬스터만
	local mg=Duel.GetFusionMaterial(tp)
	mg=mg:Filter(s.fieldmatfilter,nil,e)

	-- 유니온을 컨트롤하고 있다면, GY의 "Paper Plane" 몬스터도 소재 후보에 추가
	if s.union_present(tp) then
		local gy=Duel.GetMatchingGroup(s.gymatfilter,tp,LOCATION_GRAVE,0,nil)
		if #gy>0 then
			mg:Merge(gy)
		end
	end

	if chk==0 then
		-- 재료 자체가 최소 1장은 있어야 하고
		if #mg==0 then return false end
		-- 그 재료로 실제 융합 가능한 "Paper Plane" 융합 몬스터가 있어야 함
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--------------------------------
-- ① 융합 소환 처리
--------------------------------
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and PLAYER_NONE or tp

	-- 다시 한 번 소재 그룹 생성
	local mg=Duel.GetFusionMaterial(tp)
	mg=mg:Filter(s.fieldmatfilter,nil,e)
	if s.union_present(tp) then
		local gy=Duel.GetMatchingGroup(s.gymatfilter,tp,LOCATION_GRAVE,0,nil)
		if #gy>0 then
			mg:Merge(gy)
		end
	end
	if #mg==0 then return end

	-- 소환할 "Paper Plane" 융합 몬스터 선택
	-- → 실제로 이 mg로 융합 가능한 것만 리스트에 뜸
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,chkf)
	local tc=sg:GetFirst()
	if not tc then return end

	-- 융합 소재 선택
	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
	if not mat or #mat==0 then return end
	tc:SetMaterial(mat)

	-- GY에서 선택된 "Paper Plane" 몬스터는 덱으로 되돌리고 섞기,
	-- 나머지 소재는 일반적으로 GY로 보냄
	local gyMat=mat:Filter(s.gymatfilter,nil)
	mat:Sub(gyMat)
	if #mat>0 then
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	end
	if #gyMat>0 then
		Duel.SendtoDeck(gyMat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	end

	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end

--------------------------------
-- ② GY에서 드로우 조건
-- "Paper Plane" 몬스터가 상대 카드 때문에 필드를 떠난 경우
--------------------------------
function s.cfilter(c,tp)
	return c:IsPreviousControler(tp)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsSetCard(0xc53)
		and c:IsReason(REASON_EFFECT+REASON_BATTLE)
		and c:GetReasonPlayer()==1-tp
end
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end
