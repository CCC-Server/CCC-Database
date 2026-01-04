-- 가비지 시티
local s,id=GetID()
function s.initial_effect(c)
	-- "가비지 로드"의 카드명이 쓰여짐
	s.listed_names={44682448}

	-- 발동 (필드 마법 기본 발동)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ①: 자신의 LP가 줄어들었을 경우에 발동할 수 있다. (데미지 / 지불)
	-- 덱 / 묘지에서 "가비지 로드" 관련 몬스터 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_DAMAGE) -- 데미지를 받았을 때
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- LP를 지불했을 때도 발동 (가비지 로드 효과 발동 등)
	local e2=e1:Clone()
	-- [수정됨] EVENT_PAY_LP -> EVENT_PAY_LPCOST (올바른 이벤트 코드)
	e2:SetCode(EVENT_PAY_LPCOST) 
	e2:SetCondition(s.spcon2)
	c:RegisterEffect(e2)

	-- ②: 몬스터의 효과가 발동했을 경우, 필드의 몬스터 1장을 대상으로 하고 발동.
	-- 그 카드를 파괴하고, 공격력만큼 회복.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- "가비지 로드"의 코드
local CARD_GARBAGE_LORD = 44682448

-- [안전한 확인 함수] 가비지 로드가 기재되어 있는지 확인
function s.is_listed_safe(c)
	if not c then return false end
	-- 1. 코어 함수가 있으면 시도
	if c.IsCodeListed and c:IsCodeListed(CARD_GARBAGE_LORD) then return true end
	-- 2. Lua 테이블(listed_names)이 있으면 직접 확인 (커스텀 카드 호환)
	if c.listed_names then
		for _,code in ipairs(c.listed_names) do
			if code==CARD_GARBAGE_LORD then return true end
		end
	end
	return false
end

-- ① 효과 조건: 자신이 데미지를 받음
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return ep==tp
end
-- ① 효과 조건: 자신이 LP를 지불함
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return ep==tp
end

-- ① 효과 필터 및 처리
function s.spfilter(c,e,tp)
	-- [수정됨] aux.IsCodeListed 대신 s.is_listed_safe 사용
	return (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ② 효과 조건: 몬스터 효과 발동
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER)
end

-- ② 효과 처리
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local atk=tc:GetAttack()
		if atk<0 then atk=0 end
		if Duel.Destroy(tc,REASON_EFFECT)~=0 then
			Duel.Recover(tp,atk,REASON_EFFECT)
		end
	end
end