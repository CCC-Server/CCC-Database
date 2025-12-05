--Aero Maneuver Ace - Turbulence
local s,id=GetID()

-- 카드군 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50	  -- "Fight Call"

function s.initial_effect(c)
	--------------------------------
	-- 엑시즈 소환 조건 : 레벨 6 WIND 2장
	--------------------------------
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WIND),6,2)
	c:EnableReviveLimit()

	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 엑시즈 소환 성공시, 이 턴 동안
	--	 필드에서 패로 되돌아간 카드와 같은 이름의 몬스터를
	--	 상대는 패에서 특수 소환할 수 없음
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	-- 이 카드명 (1)번 효과는 1턴에 1번
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.e1con)
	e1:SetOperation(s.e1op)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 소재 1개 떼고, 필드 / 묘지의 카드 1장을 패로 되돌림 (속공 효과)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	-- 이 카드명 (2)번 효과는 1턴에 1번
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--------------------------------
	-- (3) 묘지에서 제외하고, 패 / 묘지의 "Aero Maneuver" 특수 소환
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	-- 이 카드명 (3)번 효과는 1턴에 1번
	e3:SetCountLimit(1,{id,2})
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--------------------------------
-- 공통 : 필드에서 패로 되돌아간 카드 판정
--------------------------------
function s.thfieldfilter(c)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end

--------------------------------
-- (1) 조건 : 엑시즈 소환으로 특수 소환된 경우
--------------------------------
function s.e1con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_XYZ)
end

--------------------------------
-- (1) 처리 : 이 턴 동안 필드에서 패로 되돌아간 카드들을 감시하고,
-- 그 카드명과 같은 몬스터를 상대가 패에서 특소하는 것을 금지하는 효과를 부여
--------------------------------
function s.e1op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 이 턴 동안 EVENT_TO_HAND를 감시하는 지속 효과
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetOperation(s.regop)
	Duel.RegisterEffect(e1,tp)
end

-- EVENT_TO_HAND 발생시 처리
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	-- 필드에서 패로 되돌아간 카드만 추출
	local g=eg:Filter(s.thfieldfilter,nil)
	if #g==0 then return end
	for tc in aux.Next(g) do
		local code=tc:GetCode()
		-- 해당 카드명 몬스터의 패에서의 특수 소환을 막는 효과 생성
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,3)) -- 클라이언트 힌트용 텍스트
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(0,1) -- 상대만
		e1:SetTarget(s.splimit1)
		e1:SetLabel(code)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- 패에서의 특수 소환만 제한, 이름은 레이블(되돌아간 카드명)과 동일해야 함
function s.splimit1(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_HAND) and c:IsCode(e:GetLabel())
end

--------------------------------
-- (2) 코스트 : 엑시즈 소재 1개 제거
--------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

--------------------------------
-- (2) 패로 되돌릴 카드 타깃 설정
-- 필드 / 묘지의 카드 1장
--------------------------------
function s.rthfilter(c)
	return c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return (chkc:IsOnField() or chkc:IsLocation(LOCATION_GRAVE))
			and s.rthfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.rthfilter,tp,
			LOCATION_ONFIELD+LOCATION_GRAVE,
			LOCATION_ONFIELD+LOCATION_GRAVE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.rthfilter,tp,
		LOCATION_ONFIELD+LOCATION_GRAVE,
		LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

--------------------------------
-- (3) 코스트 : 이 카드를 묘지에서 제외
--------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

--------------------------------
-- (3) 특수 소환 대상 : 패 / 묘지의 "Aero Maneuver" 몬스터 1장
--------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_AEROMANEUVER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,
				LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
		LOCATION_HAND+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,
		aux.NecroValleyFilter(s.spfilter),
		tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
