--헤블론-죽은 자의 성
local s,id=GetID()
function s.initial_effect(c)
	--이 카드명의 카드는 1턴에 1장밖에 발동할 수 없음
	--①: 이 카드의 발동시의 효과 처리로서, 덱에서 "헤블론" 카드 1장을 패에 넣을 수 있다
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)  -- ✅ 이 카드명의 카드는 1턴에 1장밖에 발동할 수 없음 (①효과도 자동으로 1턴 1회가 됨)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--②: 자신 필드의 빛/어둠 속성 엑시즈 1장 + 자신 묘지의 "헤블론" 몬스터 1장을 대상으로 발동,
	--    그 묘지의 몬스터를 그 엑시즈 몬스터의 엑시즈 소재로 함
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})  -- ✅ 이 카드명의 ②의 효과는 1턴에 1번만 사용 가능
	e2:SetTarget(s.mattg)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)
end

--① 덱에서 "헤블론" 카드 1장을 패에 넣을 수 있다 (may 효과: 카드 발동 자체는 항상 가능)
function s.thfilter(c)
	return c:IsSetCard(0xc06) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--② 대상: 자신 필드의 빛/어둠 속성 엑시즈 1장 + 자신 묘지의 "헤블론" 몬스터 1장
function s.xyzfilter(c,e)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
		and not c:IsImmuneToEffect(e)
end
function s.matfilter(c)
	return c:IsSetCard(0xc06) and c:IsType(TYPE_MONSTER)
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,e)
			and Duel.IsExistingTarget(s.matfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,e)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_GRAVE,0,1,1,nil)
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	if not tg or tg:FilterCount(Card.IsRelateToEffect,nil,e)<2 then return end
	local xyz=tg:Filter(Card.IsLocation,nil,LOCATION_MZONE):GetFirst()
	local mat=tg:Filter(Card.IsLocation,nil,LOCATION_GRAVE):GetFirst()
	if xyz and mat then
		Duel.Overlay(xyz,Group.FromCards(mat))
	end
end
