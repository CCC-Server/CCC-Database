--제 9사도-건설자 루크 엑스 루체 칼리고
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 레벨 12 몬스터 × 2
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsLevel,13),5)
	c:EnableReviveLimit()
	-- 룰상 "헤블론" 카드로도 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0xc06)
	c:RegisterEffect(e0)

	-- "제 9사도-건설자 루크" 위에 겹쳐 엑시즈 소환
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.ovcon)
	e1:SetOperation(s.ovop)
	c:RegisterEffect(e1)

	-- ①: 자신 필드의 카드를 상대는 효과의 대상으로 할 수 없음
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,0)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	-- ②: 공격력 / 수비력 = 엑시즈 소재 × 500
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetValue(s.statval)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)

	-- ③: 상대 메인 페이즈에 상대 몬스터 효과 발동 시
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_DRAW)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+1)
	e5:SetCondition(s.negcon)
	e5:SetCost(s.negcost)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
end

--================================================
-- 엑시즈 소환
--================================================

function s.ovfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_LUKE)
end

function s.ovcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.ovfilter,tp,LOCATION_MZONE,0,1,nil
		)
end

function s.ovop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectMatchingCard(
		tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil
	)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end

--================================================
-- ② 공격력 / 수비력 상승
--================================================

function s.statval(e,c)
	return c:GetOverlayCount()*500
end

--================================================
-- ③ 상대 메인 페이즈에 몬스터 효과 발동
--================================================

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 발동한 효과여야 함
	if rp==tp then return false end

	-- 상대 메인 페이즈인지 확인
	if Duel.GetCurrentPhase()~=PHASE_MAIN1
		and Duel.GetCurrentPhase()~=PHASE_MAIN2 then
		return false
	end

	-- 몬스터 효과인지 확인
	local rc=re:GetHandler()
	return rc:IsType(TYPE_MONSTER)
end

-- 엑시즈 소재 4개 제거
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():CheckRemoveOverlayCard(
			tp,4,REASON_COST
		)
	end

	e:GetHandler():RemoveOverlayCard(
		tp,4,4,REASON_COST
	)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	-- 상대가 1장 드로우한다는 처리
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(
		0,CATEGORY_DRAW,nil,0,1-tp,1
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=re:GetHandler()

	-- 발동한 몬스터를 이 카드의 엑시즈 소재로 한다.
	if tc:IsRelateToEffect(re) then
		Duel.Overlay(c,Group.FromCards(tc))
	end

	-- 그 후 상대는 덱에서 1장 드로우
	Duel.Draw(1-tp,1,REASON_EFFECT)
end