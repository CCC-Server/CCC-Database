--Fight Call - Boom & Zoom
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50      -- "Fight Call"

function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 발동 효과
	--  코스트: 자신 필드의 WIND 몬스터 1장을 패로 되돌린다.
	--  효과: 상대 필드의 카드 1장을 "고르고" 파괴(비대상),
	--        그 후 패에서 레벨 3 이하 WIND 몬스터 1장을 특수 소환할 수 있다.
	--        이 턴 동안 WIND 이외의 몬스터는 특수 소환할 수 없다.
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 비대상 효과이므로 EFFECT_FLAG_CARD_TARGET 사용 X
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------
-- 코스트: 자신 필드의 WIND 몬스터 1장을 패로
--------------------------------
function s.costfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WIND)
		and c:IsMonster() and c:IsAbleToHandAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SendtoHand(g,nil,REASON_COST)
end

--------------------------------
-- 파괴용 필터 (상대 필드 카드)
--------------------------------
function s.desfilter(c)
	return c:IsDestructable()
end

--------------------------------
-- (1) 타깃 설정
--  비대상 파괴이므로 대상 지정은 하지 않고,
--  파괴 가능한 카드가 있는지만 체크
--------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil)
	end
	-- 비대상 파괴: 그룹은 nil로 두고 위치/개수만 알림
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

--------------------------------
-- 특수 소환용 필터
--------------------------------
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_WIND) and c:IsLevelBelow(3)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--------------------------------
-- (1) 처리
-- 1) 상대 카드 1장 "고르고" 파괴 (비대상)
-- 2) (선택) 패에서 L3 이하 WIND 특소
-- 3) 이후 턴 종료시까지 WIND 이외 특소 불가
--------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- 1) 상대 카드 1장 고르고 파괴 (비대상)
	if Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end

	-- 2) 그 후, (선택) 패에서 레벨 3 이하 WIND 특소
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
		if #sg>0 then
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end

	-- 3) 이후 턴 종료시까지 WIND 이외 특수 소환 불가
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2)) -- "이 턴 동안 WIND 이외의 몬스터는 특수 소환할 수 없다"
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- WIND 이외 특수 소환 봉인
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsAttribute(ATTRIBUTE_WIND)
end
