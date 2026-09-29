--제 9사도-건설자 루크 렉스 루미니스
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 레벨 12 몬스터 × 2
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsLevel,13),5)
	c:EnableReviveLimit()
	--룰상 "헤블론" 카드로 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0xc06)
	c:RegisterEffect(e0)

	-- 엑스트라 덱에서 "제 9사도-건설자 루크" 위에 겹쳐 엑시즈 소환
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.ovcon)
	e1:SetOperation(s.ovop)
	c:RegisterEffect(e1)

	-- ①: 자신을 대상으로 하는 효과 이외의 상대 효과를 받지 않음
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)

	-- ②: 엑시즈 소재의 수 × 500만큼 공격력/수비력 상승
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	e4:SetValue(s.defval)
	c:RegisterEffect(e4)

	-- ③: 상대가 마법/함정 카드의 효과를 발동했을 때
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_NEGATE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_CHAIN)
	e5:SetCondition(s.negcon)
	e5:SetCost(s.negcost)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
end

-- ========================================
-- 엑시즈 소환 조건
-- ========================================

function s.ovfilter(c)
	return c:IsFaceup() and c:IsCode(128810143)
end

function s.ovcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(
		s.ovfilter,tp,LOCATION_MZONE,0,1,nil
	)
end

function s.ovop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end

-- ========================================
-- ①: 상대가 발동한 효과에 대한 내성
-- 자신을 대상으로 하는 효과는 제외
-- ========================================

function s.immval(e,re)
	local tp=e:GetHandlerPlayer()

	-- 상대가 발동한 효과만 내성을 적용
	if re:GetOwnerPlayer()~=1-tp then
		return false
	end

	-- 이 카드를 대상으로 하는 효과는 내성을 적용하지 않음
	if re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		return false
	end

	return true
end

-- ========================================
-- ②: 엑시즈 소재의 수 × 500
-- ========================================

function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

function s.defval(e,c)
	return c:GetOverlayCount()*500
end

-- ========================================
-- ③: 마법/함정 효과 발동 무효
-- ========================================

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 발동한 효과인지 확인
	if rp==tp then return false end

	-- 마법/함정 카드의 효과인지 확인
	local rc=re:GetHandler()
	return rc:IsType(TYPE_SPELL+TYPE_TRAP)
end

-- 엑시즈 소재 3개 제거
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():CheckRemoveOverlayCard(tp,3,REASON_COST)
	end

	e:GetHandler():RemoveOverlayCard(tp,3,3,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	-- 발동 무효
	if Duel.NegateActivation(ev) then
		-- 발동한 마법/함정 카드를 이 카드의 엑시즈 소재로 함
		local tc=re:GetHandler()
		if tc:IsRelateToEffect(re) then
			Duel.Overlay(e:GetHandler(),Group.FromCards(tc))
		end
	end
end