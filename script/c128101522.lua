--마린세스 하트 오브 오션
--Marincess Heart of Ocean
local s,id=GetID()
function s.initial_effect(c)
	--①: 덱에서 "마린세스" 몬스터 1장을 패에 넣는다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--②: 상대가 카드의 효과를 발동했을 경우, 묘지의 이 카드를 제외하고 링크 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.lkcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.lktg)
	e2:SetOperation(s.lkop)
	c:RegisterEffect(e2)
end

-- 유저가 제공한 배틀오션 번호
local CARD_BATTLE_OCEAN = 91027843

s.listed_names={CARD_BATTLE_OCEAN}
s.listed_series={SET_MARINCESS}

-- ①번 효과 로직 (몬스터 서치 + 조건부 함정 서치)
function s.thmonfilter(c)
	return c:IsSetCard(SET_MARINCESS) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtrapfilter(c)
	return c:IsSetCard(SET_MARINCESS) and c:IsTrap() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thmonfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thmonfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		-- 필드 존의 배틀오션 존재 확인
		local ocean=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_BATTLE_OCEAN),tp,LOCATION_FZONE,0,1,nil)
		local tg=Duel.GetMatchingGroup(s.thtrapfilter,tp,LOCATION_DECK,0,nil)
		-- 배틀오션이 있고 덱에 마린세스 함정이 있을 경우 추가 서치 여부 확인
		if ocean and #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=tg:Select(tp,1,1,nil)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

-- ②번 효과 로직 (상대 효과 발동 시 묘지에서 링크 소환)
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp -- 상대가 발동했을 때만
end
function s.lkmatfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MARINCESS) and c:IsCanBeLinkMaterial()
end
function s.lkfilter(c,mg)
	-- 자신 필드의 마린세스 몬스터들(mg)만 소재로 사용하여 소환 가능한 마린세스 링크 몬스터
	return c:IsSetCard(SET_MARINCESS) and c:IsType(TYPE_LINK) and c:IsLinkSummonable(mg)
end
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local mg=Duel.GetMatchingGroup(s.lkmatfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,mg) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.lkmatfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.lkfilter,tp,LOCATION_EXTRA,0,1,1,nil,mg)
	local tc=g:GetFirst()
	if tc then
		Duel.LinkSummon(tp,tc,mg)
	end
end