--Aero Maneuver Ace - Jetstream
local s,id=GetID()

-- 카드군 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50	  -- "Fight Call"

function s.initial_effect(c)
	--------------------------------
	-- 엑시즈 소환 조건 : 레벨 9 WIND 2장
	-- (텍스트는 2+ 이지만, 기본 절차상 2장 기준. 2+로 바꾸고 싶으면 나중에 따로 손봐도 됨)
	--------------------------------
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WIND),9,2)
	c:EnableReviveLimit()

	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 이 카드가 필드에 존재하는 동안,
	--	 상대 필드의 카드가 패로 되돌려지면
	--	 그 카드와 같은 이름의 카드 효과를 이 턴 동안 무효
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetOperation(s.e1op)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 소재 1개 떼고,
	--	 덱에서 "Aero Maneuver" 몬스터 또는 "Fight Call" 카드 1장 서치
	--	 (내 묘지에 있는 카드들과는 이름이 달라야 함)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0)) -- (2)번 효과 텍스트
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1}) -- 이 카드명 (2)번 효과는 1턴에 1번
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--------------------------------
	-- (3) 묘지에서 속공으로 스스로 특수 소환
	--	 비용: 자신 필드의 "Aero Maneuver" 몬스터 1장을 패로 되돌림
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1)) -- (3)번 효과 텍스트
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e3:SetCountLimit(1,{id,2}) -- 이 카드명 (3)번 효과는 1턴에 1번
	e3:SetCost(s.gyspcost)
	e3:SetTarget(s.gysptg)
	e3:SetOperation(s.gyspop)
	c:RegisterEffect(e3)
end

--------------------------------
-- (1) 처리부
--------------------------------
-- 상대 필드에서 패로 되돌아간 카드만 추출
function s.e1filter(c,opp)
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(opp)
end

function s.e1op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() then return end
	-- 상대 필드에서 패로 되돌아간 카드
	local g=eg:Filter(s.e1filter,nil,1-tp)
	if #g==0 then return end

	for tc in aux.Next(g) do
		local code=tc:GetCode()

		-- ①: 그 이름의 카드 효과 발동을 막음
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,2)) -- 클라이언트 힌트용 텍스트 ("그 이름의 카드 효과는 이 턴 동안 무효" 등)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetTargetRange(1,1) -- 양쪽 모두
		e1:SetLabel(code)
		e1:SetValue(s.aclimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

		-- ②: 이미 필드에 앞면 표시로 존재하는 같은 이름의 카드는 효과 무효화
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetTargetRange(LOCATION_ONFIELD,LOCATION_ONFIELD)
		e2:SetLabel(code)
		e2:SetTarget(s.distg)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)

		local e3=e2:Clone()
		e3:SetCode(EFFECT_DISABLE_EFFECT)
		Duel.RegisterEffect(e3,tp)
	end
end

-- 해당 이름의 카드/효과만 발동 금지
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return rc:IsCode(e:GetLabel())
end

-- 필드 위의 같은 이름 카드 효과 무효
function s.distg(e,c)
	return c:IsFaceup() and c:IsCode(e:GetLabel())
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
-- (2) 서치용 필터
-- 덱에서 가져올 카드:
--   - "Aero Maneuver" 몬스터
--   - 또는 "Fight Call" 카드
--   + 내 묘지에 같은 이름(카드명)의 카드가 없어야 함
--------------------------------
function s.gycodefilter(c,code)
	return c:IsCode(code)
end

function s.thfilter(c,tp)
	if not (
		((c:IsSetCard(SET_AEROMANEUVER) and c:IsMonster()) or c:IsSetCard(SET_FIGHTCALL))
		and c:IsAbleToHand()
	) then
		return false
	end
	-- 묘지에 같은 이름이 있으면 안 됨
	return not Duel.IsExistingMatchingCard(s.gycodefilter,tp,LOCATION_GRAVE,0,1,nil,c:GetCode())
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,tp)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------
-- (3) 코스트 : 자신 필드의 "Aero Maneuver" 몬스터 1장을 패로 되돌림
--------------------------------
function s.gyspcostfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_AEROMANEUVER)
		and c:IsMonster() and c:IsAbleToHandAsCost()
end

function s.gyspcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.gyspcostfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,s.gyspcostfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SendtoHand(g,nil,REASON_COST)
end

--------------------------------
-- (3) 묘지에서 자기 자신 특수 소환
--------------------------------
function s.gysptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.gyspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end
