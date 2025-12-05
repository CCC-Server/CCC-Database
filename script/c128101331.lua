--Metaphys Pendulum (Custom)
local s,id=GetID()
-- ★ 메타파이즈(커스텀) 시리즈 세트 코드
local SET_METAPHYS=0x105

function s.initial_effect(c)
	-- 펜듈럼 소환 처리
	Pendulum.AddProcedure(c)
	--------------------------------
	-- [펜듈럼 효과]
	-- ①: 메인 페이즈에 펜듈럼 존의 이 카드를 특수 소환하고,
	--    그 후 덱 / 앞면 엑스트라 덱에서 "메타파이즈" 펜듈럼 1장을 펜듈럼 존에 놓을 수 있다.
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	-- "이 카드명의 펜듈럼 효과는 1턴에 1번만 사용할 수 있다."
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.pztg)
	e1:SetOperation(s.pzop)
	c:RegisterEffect(e1)

	--------------------------------
	-- [몬스터 효과 ①]
	-- 일반 / 특수 소환 성공시: 패 / 묘지의 "메타파이즈" 카드 1장을 제외.
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	-- "이 카드명의 ①②③의 효과는 1턴에 1번만 사용할 수 있다." → 3개 효과 공통 카운트
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	--------------------------------
	-- [몬스터 효과 ②]
	-- (속공): 필드 / 앞면 엑스트라 덱의 이 카드를 제외하고,
	--         묘지의 "메타파이즈" 몬스터 1장을 특수 소환.
	--------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)

	--------------------------------
	-- [몬스터 효과 ③]
	-- 제외 상태인 이 카드가 있는 동안 카드가 제외되었을 때:
	-- 제외된 "메타파이즈" 몬스터 1장을 특수 소환.
	--------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_REMOVE)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetRange(LOCATION_REMOVED)
	e5:SetCountLimit(1,{id,1})
	e5:SetTarget(s.bstg)
	e5:SetOperation(s.bspop)
	c:RegisterEffect(e5)
end

-- 시리즈 정보(검색용)
s.listed_series={SET_METAPHYS}

----------------------------------------------------------
-- [펜듈럼 효과] 본체를 특수 소환 + 메타파이즈 펜듈럼 세팅
----------------------------------------------------------
-- "메타파이즈" 펜듈럼 몬스터 필터 (덱 / 앞면 엑스트라)
function s.pzfilter(c)
	return c:IsSetCard(SET_METAPHYS) and c:IsType(TYPE_PENDULUM)
		and not c:IsForbidden()
		and (c:IsLocation(LOCATION_DECK) or c:IsFaceup())
end

function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	-- 펜듈럼 존에서 이 카드 특수 소환
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 소환에 성공했고, 펜듈럼 존에 빈 칸이 있을 때만 추가 처리
		if not Duel.CheckPendulumZones(tp) then return end
		if not Duel.IsExistingMatchingCard(s.pzfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil) then return end
		-- "그리고 그렇게 했다면, 1장을 놓을 수 있다." → 선택 여부
		if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
			local g=Duel.SelectMatchingCard(tp,s.pzfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil)
			local tc=g:GetFirst()
			if tc then
				Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
			end
		end
	end
end

----------------------------------------------------------
-- [몬스터 효과 ①] 소환시 "메타파이즈" 카드 1장 제외
----------------------------------------------------------
function s.rmfilter(c)
	return c:IsSetCard(SET_METAPHYS) and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.rmfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

----------------------------------------------------------
-- [몬스터 효과 ②] 속공, 자신 제외하고 묘지의 메타파이즈 특소
----------------------------------------------------------
-- 코스트: 이 카드 제외 (필드 또는 앞면 엑스트라)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsFaceup() and c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-- 묘지의 "메타파이즈" 몬스터 필터
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_METAPHYS) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

----------------------------------------------------------
-- [몬스터 효과 ③] 제외 상태에서 다른 카드가 제외되면, 제외된 메타파이즈 특소
----------------------------------------------------------
-- 제외 존의 "메타파이즈" 몬스터 필터
function s.bspfilter(c,e,tp)
	return c:IsSetCard(SET_METAPHYS) and c:IsType(TYPE_MONSTER)
		and c:IsFaceup() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.bstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.bspfilter,tp,LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_REMOVED)
end

function s.bspop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.bspfilter,tp,LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
