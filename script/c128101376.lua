--Aero Maneuver Ace - Windshear
local s,id=GetID()

-- 카드군 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50	  -- "Fight Call"

function s.initial_effect(c)
	--------------------------------
	-- 엑시즈 소환 조건 : 레벨 3 WIND 2장
	--------------------------------
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WIND),3,2)
	c:EnableReviveLimit()

	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 엑시즈 소환 성공시
	--	 자신 필드 몬스터 1장 + 상대 필드 카드 1장을 패로 되돌림
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	-- 이 카드명 (1)번 효과는 1턴에 1번
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.e1con)
	e1:SetTarget(s.e1tg)
	e1:SetOperation(s.e1op)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 속공 : 소재 1개 떼고
	--	 묘지의 "Aero Maneuver" 몬스터 또는 "Fight Call" 카드 1장 회수
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	-- 이 카드명 (2)번 효과는 1턴에 1번
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.e2cost)
	e2:SetTarget(s.e2tg)
	e2:SetOperation(s.e2op)
	c:RegisterEffect(e2)
end

--------------------------------
-- (1) 조건 : 엑시즈 소환으로 특수 소환된 경우
--------------------------------
function s.e1con(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

--------------------------------
-- (1) 타깃 / 처리
-- 자신 몬스터 1장 + 상대 필드 카드 1장 패로
--------------------------------
function s.e1myfilter(c)
	return c:IsMonster() and c:IsAbleToHand()
end
function s.e1opfilter(c)
	return c:IsAbleToHand()
end

function s.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingTarget(s.e1myfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingTarget(s.e1opfilter,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g1=Duel.SelectTarget(tp,s.e1myfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g2=Duel.SelectTarget(tp,s.e1opfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g1,#g1,0,0)
end

function s.e1op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end

--------------------------------
-- (2) 코스트 : 엑시즈 소재 1개 제거
--------------------------------
function s.e2cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

--------------------------------
-- (2) 서치용 필터
-- "Aero Maneuver" 몬스터 또는 "Fight Call" 카드 (묘지)
--------------------------------
function s.e2filter(c)
	return (((c:IsSetCard(SET_AEROMANEUVER) and c:IsMonster())
		or c:IsSetCard(SET_FIGHTCALL))
		and c:IsAbleToHand())
end

function s.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.e2filter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.e2op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.e2filter),
		tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
