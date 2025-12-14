--스펠크래프트 매직코어
local s,id=GetID()
function s.initial_effect(c)
	-------------------------------
	-- 기본 설정 / 제한
	-------------------------------
	c:SetUniqueOnField(1,0,id) -- 동일명 카드 필드 1장 제한
	c:EnableCounterPermit(0x1) -- 마력 카운터 허용 (COUNTER_SPELL = 0x1)
	-- E0 : 기본 발동
local e0=Effect.CreateEffect(c)
e0:SetType(EFFECT_TYPE_ACTIVATE)
e0:SetCode(EVENT_FREE_CHAIN)
c:RegisterEffect(e0)

	-------------------------------
	-- ① : 카운터 추가
	-------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_SZONE)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	
	-------------------------------
	-- ② : 대상 내성 (스펠크래프트 몬스터 존재 시)
	-------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.tgcon)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	
	-------------------------------
	-- ③ : 묘지로 보내졌을 때 데미지
	-------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,1}) -- ③의 효과는 1턴에 1번
	e3:SetCondition(s.damcon)
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end
-----------------------------------------------------------
-- "스펠크래프트" 관련 세트 코드 (실제 코드로 교체 가능)
-----------------------------------------------------------
s.listed_series={0x1A2B} -- 예시 : 스펠크래프트 시리즈

-----------------------------------------------------------
-- ① : 카운터 추가 (발동할 때마다 1개)
-----------------------------------------------------------
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c or not c:IsLocation(LOCATION_SZONE) then return end
	-- 오직 자신이 발동할 때만
	if rp~=tp then return end
	
	-- 마법 카드 발동 or 스펠크래프트 몬스터 효과 발동
	local rc=re:GetHandler()
	local isSpell = re:IsActiveType(TYPE_SPELL)
	local isScMonsterEff = rc:IsSetCard(0x761) and re:IsActiveType(TYPE_MONSTER)
	if isSpell or isScMonsterEff then
		c:AddCounter(0x1,1)
		Duel.Hint(HINT_CARD,0,id) -- 확인용 힌트 (게임 내 표시용)
	end
end

-----------------------------------------------------------
-- ② : 자신 필드에 "스펠크래프트" 몬스터 존재 시 대상 내성
-----------------------------------------------------------
function s.tgcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.scfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x1A2B)
end

-----------------------------------------------------------
-- ③ : 상대 효과로 묘지로 보내졌을 경우 데미지
-----------------------------------------------------------
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp~=tp and c:IsPreviousControler(tp)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=e:GetHandler():GetCounter(0x1)
	if chk==0 then return ct>0 end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(ct*300)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*300)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end
