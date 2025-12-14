--Dragon Dual Synthesis (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--① 발동 효과
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) --이 카드명의 카드는 1턴에 1장 제한
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--① 패 1장 버리는 코스트
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,0) and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

--드래곤족 / 듀얼 몬스터 서치 필터
function s.thfilter(c)
	return (c:IsRace(RACE_DRAGON) or c:IsType(TYPE_GEMINI)) and c:IsAbleToHand()
end

--① 대상 지정
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--① 발동 처리
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--드래곤족/듀얼 몬스터 2장까지, 같은 이름은 1장만 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g==0 then return end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,2,aux.dncheck,1,tp,HINTMSG_ATOHAND)
	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end

	--필드에 듀얼 상태 몬스터가 있을 경우 1000 LP 회복
	if Duel.IsExistingMatchingCard(s.gemini_filter,tp,LOCATION_MZONE,0,1,nil) then
		Duel.Recover(tp,1000,REASON_EFFECT)
	end
end

--듀얼 상태 확인용 필터
function s.gemini_filter(c)
	return c:IsFaceup() and c:IsType(TYPE_GEMINI) and c:IsGeminiState()
end
