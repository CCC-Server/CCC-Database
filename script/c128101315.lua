-- 하피 엑시즈 몬스터 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_WIND),4,2)
	c:EnableReviveLimit()

	--①: 소환 성공 or 몬스터 효과 발동 시 되돌리기
	local e1a=Effect.CreateEffect(c)
	e1a:SetDescription(aux.Stringid(id,0))
	e1a:SetCategory(CATEGORY_TOHAND)
	e1a:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1a:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1a:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1a:SetCountLimit(1,id)
	e1a:SetCondition(s.bouncecon1a)
	e1a:SetTarget(s.bouncetg)
	e1a:SetOperation(s.bounceop)
	c:RegisterEffect(e1a)

	local e1b=Effect.CreateEffect(c)
	e1b:SetDescription(aux.Stringid(id,0))
	e1b:SetCategory(CATEGORY_TOHAND)
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1b:SetCode(EVENT_CHAINING)
	e1b:SetRange(LOCATION_MZONE)
	e1b:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1b:SetCountLimit(1,id)
	e1b:SetCondition(s.bouncecon1b)
	e1b:SetTarget(s.bouncetg)
	e1b:SetOperation(s.bounceop)
	c:RegisterEffect(e1b)

	--②: 검색 + 추가 특소 조건부
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- 카드군 등록
s.listed_series={SET_HARPIE}

--------------------------------
-- ① 조건: 엑시즈 소환 성공 시
function s.bouncecon1a(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

-- ① 조건: 몬스터 효과 발동 시
function s.bouncecon1b(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER)
end

-- 공통 타겟 및 작동 (①)
function s.bouncetg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.bounceop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

--------------------------------
-- ②: 비용으로 엑시즈 소재 1개 제거
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ②: 덱에서 "해피" 몬스터 서치
function s.thfilter(c)
	return c:IsSetCard(SET_HARPIE) and c:IsMonster() and c:IsAbleToHand()
end
-- ②: 추가로 묘지 특수 소환 가능한지 확인
function s.ssfilter(c,e,tp)
	return c:IsSetCard(SET_HARPIE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		-- 상대 턴에 몬스터 효과 발동했는지 확인
		if Duel.GetCurrentChain()>0 and Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.ssfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
			if #sg>0 then
				Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end
