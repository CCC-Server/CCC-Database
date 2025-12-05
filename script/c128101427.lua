--World Guardian ??? (prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- (1) 패에서 특수 소환
	------------------------------------
	-- 1-1) "World Guardian" 필드 마법 컨트롤 시: 기동 효과
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)         -- 속도 1
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)                   -- (1)번 효과 턴 1회 (트리거 버전과 공유)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- 1-2) 필드 존에 필드 마법이 있고, 상대가 마/함을 발동해 체인이 끝난 후: 패에서 특소하는 트리거 효과
	local e1b=e1:Clone()
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1b:SetCode(EVENT_CHAIN_SOLVED)          -- 체인 해결 후 새 체인으로 발동
	e1b:SetCondition(s.spcon2)
	c:RegisterEffect(e1b)
	
	------------------------------------
	-- (2) 소환 성공 시, 이 턴 동안 내 월가 몬스터 파괴 내성
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id+100)               -- (2)번 효과 턴 1회
	e2:SetTarget(s.prottg)
	e2:SetOperation(s.protop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	------------------------------------
	-- (3) 상대 카드/효과 발동 시 "World Guardian" 서치
	------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+200)               -- (3)번 효과 턴 1회
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

----------------------------------------------------------
-- (1) 패에서 특수 소환 관련
----------------------------------------------------------
-- "World Guardian" 필드 마법
function s.wgfieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end
-- 아무 필드 마법 (자신/상대)
function s.anyfieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end

-- (1-1) 조건: 내가 "World Guardian" 필드 마법을 컨트롤
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	return Duel.IsExistingMatchingCard(s.wgfieldfilter,tp,LOCATION_FZONE,0,1,nil)
end

-- (1-2) 조건:
-- 필드 존에 필드 마법 존재 +
-- 방금 해결된 체인이 상대의 마/함 카드/효과였음
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	-- 필드 존에 필드 마법
	if not Duel.IsExistingMatchingCard(s.anyfieldfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil) then
		return false
	end
	if not re then return false end
	return rp==1-tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 이 턴 동안 패에서 "World Guardian" 몬스터 특소 불가
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- 패에서의 "World Guardian" 몬스터 특소 제한
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER) and c:IsLocation(LOCATION_HAND)
end

----------------------------------------------------------
-- (2) 이 턴 동안 내 "World Guardian" 몬스터 파괴 내성
----------------------------------------------------------
function s.prottg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

-- "World Guardian" 몬스터만 적용
function s.protfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
end

function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 전투 파괴 내성
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(_,tc) return s.protfilter(tc) end)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	-- 효과 파괴 내성
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(1)
	Duel.RegisterEffect(e2,tp)
end

----------------------------------------------------------
-- (3) 상대 카드/효과 발동 시 "World Guardian" 서치
----------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end
function s.thfilter(c)
	return c:IsSetCard(0xc52) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
