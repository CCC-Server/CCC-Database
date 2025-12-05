--Fight Call - Boom & Zoom
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50	  -- "Fight Call"

function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 발동 효과
	--	 자신 WIND 몬스터 1장을 패로 되돌리고,
	--	 상대 필드의 카드 1장을 파괴한 뒤,
	--	 패에서 레벨 3 이하 WIND 몬스터 1장 특소할 수 있음
	--	 이 턴 동안 WIND 이외 특수 소환 불가
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------
-- (1) 대상 선택
--  자신 필드의 WIND 몬스터 1장 + 상대 필드의 카드 1장
--------------------------------
function s.thfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WIND)
		and c:IsMonster() and c:IsAbleToHand()
end
function s.desfilter(c)
	return c:IsDestructable()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		-- 이미 타깃 잡힌 경우 재선택 조건
		return (chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.thfilter(chkc))
			or (chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and s.desfilter(chkc))
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil)
	end
	-- 자신 WIND 몬스터 선택 (패로 되돌릴 대상)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g1=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_MZONE,0,1,1,nil)
	-- 상대 필드 파괴할 카드 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g1,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g2,1,0,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

--------------------------------
-- (1) 처리
-- 1) 자신 WIND 몬스터 패로
-- 2) 상대 카드 파괴
-- 3) (선택) 패에서 L3 이하 WIND 특소
-- 4) 이후 턴 종료시까지 WIND 이외 특소 불가
--------------------------------
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_WIND) and c:IsLevelBelow(3)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetTargetCards(e)
	if #tg==0 then return end

	-- 자신 몬스터 / 상대 카드 분리
	local th=tg:Filter(function(tc) return tc:IsControler(tp) end,nil):GetFirst()
	local des=tg:Filter(function(tc) return tc:IsControler(1-tp) end,nil):GetFirst()

	-- 1) 자신 WIND 몬스터 패로
	if th and th:IsRelateToEffect(e) then
		Duel.SendtoHand(th,nil,REASON_EFFECT)
	end

	-- 2) 상대 카드 파괴
	if des and des:IsRelateToEffect(e) then
		Duel.Destroy(des,REASON_EFFECT)
	end

	-- 3) 그 후, (선택) 패에서 레벨 3 이하 WIND 특소
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
		if #sg>0 then
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end

	-- 4) 이후 턴 종료시까지 WIND 이외 특수 소환 불가
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2)) -- "이 턴 동안 WIND 이외의 몬스터는 특수 소환할 수 없다" 안내 텍스트용
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
