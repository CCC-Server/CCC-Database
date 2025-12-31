--대괴수결전병기 - 하이퍼 X
local s,id=GetID()
function s.initial_effect(c)
	--①: 패에서 버리고, 덱/묘지의 파괴수를 상대 필드에 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: 상대 파괴수가 필드를 벗어나면, 필드/묘지의 이 카드를 제외하고 서치
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_series={0xd3, 0xc82} -- 파괴수, 대괴수결전병기

-- ①번 효과 구현
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end

function s.kaijufilter(c,e,tp)
	-- 상대 필드(1-tp)에 소환 가능한 파괴수 몬스터
	return c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 상대 필드에 파괴수가 이미 존재하면 소환 불가 (파괴수 룰)
		local opp_kaiju_exists = Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xd3),tp,0,LOCATION_MZONE,1,nil)
		return not opp_kaiju_exists 
			and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.kaijufilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	-- 효과 처리 시에도 상대 필드에 파괴수가 있으면 불발
	if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xd3),tp,0,LOCATION_MZONE,1,nil) then return end
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.kaijufilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,1-tp,false,false,POS_FACEUP)
	end
end

-- ②번 효과 구현
function s.cfilter(c,tp)
	-- 상대 필드(1-tp)에서(PreviousLocation) 벗어난 파괴수 몬스터
	return c:IsPreviousControler(1-tp) and c:IsPreviousLocation(LOCATION_MZONE) 
		and c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.thfilter(c)
	return c:IsSetCard(0xc82) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end