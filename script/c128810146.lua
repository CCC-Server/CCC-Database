--헤블론-어둠의 우상 아누비스
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure (Dark, Level 8, 2 materials)
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK),8,2)
	c:EnableReviveLimit()

	-- ①: 이 카드의 공격력은, 이 카드의 엑시즈 소재의 수 × 500 올린다.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- ②: 자신 필드의 다른 어둠 속성 엑시즈 몬스터 1장을 대상으로 하고 발동할 수 있다. 이 카드 및 이 카드의 엑시즈 소재를 전부 그 몬스터의 엑시즈 소재로 한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOFIELD)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.ovtg)
	e2:SetOperation(s.ovop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 효과: 엑시즈 소재의 수 × 500만큼 공격력 상승
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

-- ② 타겟: 자신 필드의 다른 어둠 속성 엑시즈 몬스터 1장
function s.ovfilter(c,e)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsCanBeOverlayed() and c~=e:GetHandler()
end

function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.ovfilter(chkc,e) end
	if chk==0 then return Duel.IsExistingTarget(s.ovfilter,tp,LOCATION_MZONE,0,1,c,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,c,e)
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,c,1,0,0)
end

-- ② 처리: 이 카드 및 이 카드의 엑시즈 소재를 전부 그 몬스터의 엑시즈 소재로 한다.
function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local g=c:GetOverlayGroup()
		g:AddCard(c)
		Duel.Overlay(tc,g)
	end
end
