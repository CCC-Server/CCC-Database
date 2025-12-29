--헤블론-죽은 자의 성
local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드명의 카드는 1턴에 1장밖에 발동할 수 없다.
	local e0=Effect.CreateEffect(c)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- ①: 이 카드의 발동시의 효과 처리로서, 덱에서 "헤블론" 카드 1장을 패에 넣을 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: 자신 필드의 빛 / 어둠 속성 엑시즈 1장과 자신 묘지의 "헤블론" 몬스터 1장을 대상으로 하고 발동할 수 있다. 그 묘지의 "헤블론" 몬스터를 그 필드의 엑시즈 몬스터의 엑시즈 소재로 한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_OVERLAY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.ovtg)
	e2:SetOperation(s.ovop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 타겟: 덱에서 "헤블론" 카드 1장을 패에 넣을 수 있다.
function s.thfilter(c)
	return c:IsSetCard(0xc06) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ② 타겟: 자신 필드의 빛/어둠 속성 엑시즈 몬스터 1장, 자신 묘지의 "헤블론" 몬스터 1장
function s.ovfilter1(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
end

function s.ovfilter2(c)
	return c:IsSetCard(0xc06) and c:IsMonster()
end

function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local tg=Duel.GetTargetCards(chkc)
		local fc=tg:Filter(Card.IsOnField,nil):GetFirst()
		if fc and chkc==fc then
			return s.ovfilter2(chkc)
		else
			return s.ovfilter1(chkc)
		end
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.ovfilter1,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingTarget(s.ovfilter2,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g1=Duel.SelectTarget(tp,s.ovfilter1,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g2=Duel.SelectTarget(tp,s.ovfilter2,tp,LOCATION_GRAVE,0,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_OVERLAY,g2,1,0,0)
end

-- ② 처리: 묘지의 "헤블론" 몬스터를 필드의 엑시즈 몬스터의 엑시즈 소재로 한다.
function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	local fc=g:Filter(Card.IsOnField,nil):GetFirst()
	local gc=g:Filter(Card.IsLocation,nil,LOCATION_GRAVE):GetFirst()
	if fc and gc and fc:IsRelateToEffect(e) and gc:IsRelateToEffect(e) and fc:IsFaceup() then
		Duel.Overlay(fc,Group.FromCards(gc))
	end
end
