--오버 리밋 • 포뮬러 드라이브
local s,id=GetID()
function s.initial_effect(c)
	--초기 발동 (지속 함정의 발동)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--①: 카드명을 "리미터 해제"로 취급 (필드 / 묘지)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_ONFIELD+LOCATION_GRAVE)
	e1:SetValue(23171610) -- 리미터 해제 ID
	c:RegisterEffect(e1)

	--②: 상대 엑스트라 덱 몬스터 효과 무효화
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(0,LOCATION_MZONE) -- 상대 몬스터존 대상
	e2:SetCode(EFFECT_DISABLE)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	c:RegisterEffect(e2)
	-- 효과 발동도 불가능하게 함 (스킬 드레인 방식)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_DISABLE_EFFECT)
	c:RegisterEffect(e3)

	--③: "리미터 해제" 발동 시 묘지에서 세트
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.setcon)
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end

-- "리미터 해제" 카드 명시
s.listed_names={23171610}

-- ② 효과 조건: 자신 필드에 공격력이 가장 높은 몬스터가 존재해야 함
function s.discon(e)
	local tp=e:GetHandlerPlayer()
	-- 필드의 모든 앞면 표시 몬스터 확인
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g==0 then return false end
	
	-- 전체 필드에서 가장 높은 공격력을 가진 몬스터 그룹 추출
	local max_g=g:GetMaxGroup(Card.GetAttack)
	
	-- 가장 높은 공격력을 가진 몬스터 중 내 필드에 있는 몬스터가 하나라도 있으면 조건 충족
	-- (동점이어도 내 필드에 그 수치 몬스터가 있으면 적용)
	return max_g:IsExists(Card.IsControler,1,nil,tp)
end

-- ② 효과 대상: 엑스트라 덱에서 특수 소환된 상대 몬스터
function s.distg(e,c)
	return c:IsSummonLocation(LOCATION_EXTRA)
end

-- ③ 효과 조건: "리미터 해제"의 발동
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsCode(23171610)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp,c)
	end
end