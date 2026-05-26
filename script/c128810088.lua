--코스모 핀드-로젠-순백 우주
-- 코스모 핀드 - 로젠 - 순백 우주
local s,id=GetID()
function s.initial_effect(c)
	 -- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FIEND),12,2,s.ovfilter,aux.Stringid(id,0))
	c:EnableReviveLimit()

	-- Cannot be destroyed by battle
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Negate activation and attach material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.negcost)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- 카드군 정의
s.listed_series={0xc04} -- "코스모 핀드" 카드군

-- 엑시즈 소환 조건: 랭크 10 악마족 엑시즈 몬스터 위에 겹쳐 엑시즈 소환 가능
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsRace(RACE_FIEND) and c:IsRank(10) and c:IsType(TYPE_XYZ)
end

-- 소재 제거 비용
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

-- 무효화 조건
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return Duel.IsChainNegatable(ev) and 
	(re:IsHasType(EFFECT_TYPE_ACTIVATE) -- 마법/함정 카드의 발동
	or (re:IsActiveType(TYPE_MONSTER) and rc:IsOnField())) -- 필드 몬스터 효과 발동
end


-- 무효화 대상 설정
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

-- 무효화 및 엑시즈 소재로 추가
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=re:GetHandler()
	if Duel.NegateActivation(ev) and tc:IsRelateToEffect(re) then tc:CancelToGrave()
		Duel.Overlay(c,Group.FromCards(tc))
	end
end