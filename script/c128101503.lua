-- 가비지 콜렉터
local s,id=GetID()
function s.initial_effect(c)
	-- "가비지 로드", "가비지 시티"의 카드명이 쓰여짐
	s.listed_names={44682448, 1281014506}

	-- ①: 자신 필드의 몬스터가 존재하지 않을 경우 또는 "가비지 로드" 관련 몬스터 존재 시 발동.
	-- 패 특소 + 덱에서 "가비지 시티" 앞면 표시로 놓기 + 1000 데미지
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 필드의 이 카드를 소재로서 엑시즈 소환한 엑시즈 몬스터는 이하의 효과를 얻는다.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.efcon)
	e2:SetOperation(s.efop)
	c:RegisterEffect(e2)
end

-- 관련 카드 코드
local CARD_GARBAGE_LORD = 44682448
local CARD_GARBAGE_CITY = 128101506 -- 이전에 수정된 가비지 시티 ID

-- [안전한 확인 함수] 가비지 로드가 기재되어 있는지 확인
function s.is_listed_safe(c)
	if not c then return false end
	if c.IsCodeListed and c:IsCodeListed(CARD_GARBAGE_LORD) then return true end
	if c.listed_names then
		for _,code in ipairs(c.listed_names) do
			if code==CARD_GARBAGE_LORD then return true end
		end
	end
	return false
end

-- ① 효과: 조건 확인 필터
function s.cfilter(c)
	-- [수정됨] aux.IsCodeListed 대신 s.is_listed_safe 사용
	return c:IsFaceup() and (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c))
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		or Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- ① 효과: "가비지 시티" 필터
function s.cityfilter(c,tp)
	return c:IsCode(CARD_GARBAGE_CITY) and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

-- ① 효과: Target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.cityfilter,tp,LOCATION_DECK,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,1000)
end

-- ① 효과: Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 덱에서 "가비지 시티"를 필드 존에 놓는다
		local tc=Duel.GetFirstMatchingCard(s.cityfilter,tp,LOCATION_DECK,0,nil,tp)
		if tc then
			Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
			
			-- 그 후, 1000 데미지를 받는다
			Duel.BreakEffect()
			Duel.Damage(tp,1000,REASON_EFFECT)
		end
	end
end

-- ② 효과: 소재로 사용되었을 때 조건 (필드의 이 카드를 소재로 엑시즈 소환)
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_XYZ and e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end

-- ② 효과: 엑시즈 몬스터에게 효과 부여
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	
	-- 부여할 효과: 퍼미션
	local e1=Effect.CreateEffect(rc)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.gaincon)
	e1:SetTarget(s.gaintg)
	e1:SetOperation(s.gainop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e1,true)
	
	-- 효과 몬스터가 아닐 경우 효과 몬스터로 취급
	if not rc:IsType(TYPE_EFFECT) then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_ADD_TYPE)
		e2:SetValue(TYPE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e2,true)
	end
end

-- 부여된 효과: 특수 소환한 턴에 1번, 상대 효과 발동 시 무효
function s.gaincon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsStatus(STATUS_SPSUMMON_TURN) and rp==1-tp 
		and (re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE))
end

function s.gaintg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end

function s.gainop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end