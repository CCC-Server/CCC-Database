--Arsenal Gale - Dreadnought Cyclone
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50      -- "Fight Call"

-- 플래그 코드
local FLAG_BOUNCED=id          -- 이 턴에 필드→패로 되돌아간 카드가 있었는지
local FLAG_ALT=id+100          -- 이 카드의 추가 엑시즈 소환법을 썼는지

-------------------------------------------------------
-- 이 턴에 "필드의 카드가 패로 되돌아간 적이 있는가" 글로벌 체크
-------------------------------------------------------
local function global_bounced_from_field(c)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.global_bounce_reg(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(global_bounced_from_field,1,nil) then return end
	-- 양 플레이어 모두에게 "이번 턴에 바운스가 있었다" 플래그 부여
	for p=0,1 do
		if Duel.GetFlagEffect(p,FLAG_BOUNCED)==0 then
			Duel.RegisterFlagEffect(p,FLAG_BOUNCED,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

-- 전역 이펙트 등록 (스크립트 로드 시 1번만)
if not s.global_check then
	s.global_check=true
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge1:SetCode(EVENT_TO_HAND)
	ge1:SetOperation(s.global_bounce_reg)
	Duel.RegisterEffect(ge1,0)
end

-------------------------------------------------------
-- 카드 본체
-------------------------------------------------------
function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- 기본 엑시즈 소환
	-- 텍스트는 "3+ 레벨 10"이지만, 엔진상
	-- "레벨 10 몬스터 3장"으로 구현
	--------------------------------
	Xyz.AddProcedure(c,nil,10,3)
	c:EnableReviveLimit()

	--------------------------------
	-- 추가 엑시즈 소환 절차
	-- 1턴에 1번, 이 턴에 필드에서 패로 되돌아간 카드가 있었다면,
	-- 자신 필드의 랭크 3/6/9 WIND 엑시즈 1장을 소재로
	-- 이 카드를 엑시즈 소환 (소재 승계)
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon_alt)
	e0:SetOperation(s.xyzop_alt)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)

	--------------------------------
	-- (1) 속공 : 소재 2개 떼고,
	--     묘지의 WIND 몬스터 1장 특수 소환.
	--     그 몬스터가 엑시즈라면, 엑시즈 소환으로 취급하고
	--     묘지의 WIND 몬스터 2장을 그 몬스터의 소재로 겹침.
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	-- 텍스트상 ①은 1턴 1번 제한 없음 (원하면 SetCountLimit 추가 가능)
	e1:SetCost(s.spcost1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 필드 위에 존재하는 동안
	--     어느 플레이어도 상대 필드로 특수 소환할 수 없음.
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(1,1)
	e2:SetTarget(s.splimit2)
	c:RegisterEffect(e2)

	--------------------------------
	-- (3) 필드의 카드가 패로 되돌려졌을 때,
	--     필드 위 카드 1장의 효과를 턴 종료시까지 무효.
	--     이 카드명 (3)번 효과는 1턴에 1번.
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.negcon3)
	e3:SetTarget(s.negtg3)
	e3:SetOperation(s.negop3)
	c:RegisterEffect(e3)
end

-------------------------------------------------------
-- 추가 엑시즈 소환용 필터 / 조건 / 처리
-------------------------------------------------------
function s.ovfilter(c)
	return c:IsFaceup()
		and c:IsAttribute(ATTRIBUTE_WIND)
		and c:IsType(TYPE_XYZ)
		and (c:GetRank()==3 or c:GetRank()==6 or c:GetRank()==9)
end

function s.xyzcon_alt(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- 이 턴에 필드에서 패로 되돌아간 카드가 있어야 함
	if Duel.GetFlagEffect(tp,FLAG_BOUNCED)==0 then return false end
	-- 이 추가 소환법은 1턴에 1번
	if Duel.GetFlagEffect(tp,FLAG_ALT)~=0 then return false end
	if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then return false end
	return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.xyzop_alt(e,tp,eg,ep,ev,re,r,rp,c)
	local tp=c:GetControler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local mc=g:GetFirst()
	if not mc then return end
	local mg=mc:GetOverlayGroup()
	if #mg>0 then
		Duel.Overlay(c,mg)
	end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	-- 이 추가 소환법은 1턴에 1번
	Duel.RegisterFlagEffect(tp,FLAG_ALT,RESET_PHASE+PHASE_END,0,1)
end

-------------------------------------------------------
-- (1) GY WIND 특수 소환 + 엑시즈면 소재 2장 겹침
-------------------------------------------------------
function s.spcost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,2,REASON_COST)
	end
	c:RemoveOverlayCard(tp,2,2,REASON_COST)
end

function s.spfilter1(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_WIND) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.matfilter1(c)
	return c:IsAttribute(ATTRIBUTE_WIND) and c:IsMonster()
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter1(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter1,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter1,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	-- 엑시즈 몬스터라면, 엑시즈 소환으로 취급 + WIND 2장 겹침
	if tc:IsType(TYPE_XYZ) then
		tc:CompleteProcedure()
		if Duel.IsExistingMatchingCard(s.matfilter1,tp,LOCATION_GRAVE,0,1,nil) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g=Duel.SelectMatchingCard(tp,s.matfilter1,tp,LOCATION_GRAVE,0,1,2,nil)
			if #g>0 then
				Duel.Overlay(tc,g)
			end
		end
	end
end

-------------------------------------------------------
-- (2) 상대 필드로의 특수 소환 봉인
-------------------------------------------------------
-- targetp : 특수 소환 후 그 몬스터를 컨트롤할 플레이어
-- sump    : 특수 소환을 수행한 플레이어
-- → 둘이 다르면 "상대 필드로 특소"이므로 막는다
function s.splimit2(e,c,sump,sumtype,sumpos,targetp,se)
	return targetp~=sump
end

-------------------------------------------------------
-- (3) 바운스 발생시 필드의 카드 1장 효과 무효
-------------------------------------------------------
function s.cfilter3(c)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.negcon3(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter3,1,nil)
end

function s.negtg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and aux.disfilter1(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(aux.disfilter1,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,aux.disfilter1,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.negop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled()) then return end
	Duel.NegateRelatedChain(tc,RESET_TURN_SET)
	-- 효과 무효화
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	e2:SetValue(RESET_TURN_SET)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e2)
	if tc:IsType(TYPE_TRAPMONSTER) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e3)
	end
end
