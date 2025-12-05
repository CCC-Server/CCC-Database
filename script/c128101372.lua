--Aero Maneuver - Dead Vortex
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50      -- "Fight Call"

-- 이 턴에 필드에서 패로 되돌아간 카드 수를 전역으로 카운트
-- s[0] 을 카운터로 사용

-------------------------------------------------------
-- 전역 바운스 카운트용 함수들
-------------------------------------------------------
local function bounced_from_field(c)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(bounced_from_field,nil)
	if ct>0 then
		s[0]=(s[0] or 0)+ct
	end
end

function s.resetop(e,tp,eg,ep,ev,re,r,rp)
	-- 드로우 페이즈 시작마다 이 턴 카운트 리셋
	s[0]=0
end

-------------------------------------------------------
-- 전역 이펙트 등록 (스크립트 로드 시 1번만)
-------------------------------------------------------
if not s.global_check then
	s.global_check=true
	s[0]=0
	-- 필드에서 패로 되돌아간 카드 감시
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge1:SetCode(EVENT_TO_HAND)
	ge1:SetOperation(s.regop)
	Duel.RegisterEffect(ge1,0)
	-- 각 턴 드로우 페이즈 시작 시 카운트 리셋
	local ge2=Effect.GlobalEffect()
	ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
	ge2:SetOperation(s.resetop)
	Duel.RegisterEffect(ge2,0)
end

-------------------------------------------------------
-- 카드 본체
-------------------------------------------------------
function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 이 턴에 필드에서 패로 되돌아간 카드가 3장 이상이면
	--     패 / 묘지에서 프리체인 특수 소환 (속공 효과)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id) -- (1) 1턴 1번
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 필드의 카드가 패로 되돌려졌을 때,
	--     상대 필드의 카드 최대 2장까지 패로 되돌림
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1}) -- (2) 1턴 1번
	e2:SetCondition(s.thcon2)
	e2:SetTarget(s.thtg2)
	e2:SetOperation(s.thop2)
	c:RegisterEffect(e2)

	--------------------------------
	-- (3) 자신을 패로 되돌리고,
	--     덱에서 "Fight Call" 속공 마법 1장 세트
	--     (묘지에 같은 이름이 없는 카드만)
	--     이 턴에 3장 이상 바운스되어 있다면
	--     그 카드는 세트한 턴에도 발동 가능
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(0)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2}) -- (3) 1턴 1번
	e3:SetCost(s.setcost3)
	e3:SetTarget(s.settg3)
	e3:SetOperation(s.setop3)
	c:RegisterEffect(e3)
end

-------------------------------------------------------
-- (1) 특수 소환
-------------------------------------------------------
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	-- 이 턴에 필드에서 패로 되돌아간 카드가 3장 이상
	return (s[0] or 0)>=3
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

-------------------------------------------------------
-- (2) 바운스 시 상대 카드 최대 2장 바운스
-------------------------------------------------------
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	-- 필드에서 패로 되돌아간 카드가 하나라도 있는가
	return eg:IsExists(bounced_from_field,1,nil)
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsAbleToHand()
	end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,#g,0,0)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end

-------------------------------------------------------
-- (3) 자신을 패로, 덱에서 "Fight Call" 속공 마법 세트
-------------------------------------------------------
function s.setcost3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHandAsCost() end
	Duel.SendtoHand(c,nil,REASON_COST)
end

function s.setfilter3(c,tp)
	return c:IsSetCard(SET_FIGHTCALL)
		and c:IsType(TYPE_SPELL) and c:IsType(TYPE_QUICKPLAY)
		and c:IsSSetable()
		and not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,1,nil,c:GetCode())
end

function s.settg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter3,tp,LOCATION_DECK,0,1,nil,tp)
	end
end

function s.setop3(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter3,tp,LOCATION_DECK,0,1,1,nil,tp)
	local tc=g:GetFirst()
	if not tc then return end
	if Duel.SSet(tp,tc)>0 then
		if (s[0] or 0)>=3 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_CLIENT_HINT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end
