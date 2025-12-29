--헤블론-콰트로 마누스 Mk.2
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure (Level 9, 3 materials, overlay from Rank 8 Xyz)
	Xyz.AddProcedure(c,nil,9,3,s.ovfilter,aux.Stringid(id,0))
	c:EnableReviveLimit()

	-- ①: 이 카드의 공격력은, 이 카드의 엑시즈 소재의 수 × 500 올린다.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- ②: 상대가 필드의 카드의 효과를 발동했을 때, 이 카드의 엑시즈 소재를 2개 제거하고 발동할 수 있다. 그 필드의 카드를 이 카드의 엑시즈 소재로 한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOFIELD)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.ovcon)
	e2:SetCost(s.ovcost)
	e2:SetTarget(s.ovtg)
	e2:SetOperation(s.ovop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- 엑시즈 소환 조건: 랭크 8 엑시즈 몬스터 위에 겹쳐 소환
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsRank(8) and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end

-- 엑시즈 소환 시 코스트: 랭크 8 엑시즈 몬스터의 엑시즈 소재 1개 제거
function s.xyzovcost(e,tp,lc)
	local tc=Duel.GetFieldCard(tp,LOCATION_MZONE,lc)
	if tc then tc:RemoveOverlayCard(tp,1,1,REASON_COST) end
end

-- ① 효과: 엑시즈 소재의 수 × 500만큼 공격력 상승
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

-- ② 조건: 상대가 필드의 카드의 효과를 발동했을 때
function s.ovcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and rc:IsOnField() and Duel.IsChainNegatable(ev)
end

-- ② 코스트: 엑시즈 소재 2개 제거
function s.ovcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,2,REASON_COST) end
	c:RemoveOverlayCard(tp,2,2,REASON_COST)
end

-- ② 타겟: 상대 필드의 카드 1장
function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local rc=re:GetHandler()
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return rc:IsOnField() and rc:IsControler(1-tp) and rc:IsCanBeOverlayed() end
	Duel.SetTargetCard(rc)
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,rc,1,0,0)
end

-- ② 처리: 대상 카드를 엑시즈 소재로 한다
function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.Overlay(c,Group.FromCards(tc))
	end
end
