--기계천사의 개입 (예시 카드명)
local s,id=GetID()
function s.initial_effect(c)
	--①: 발동시 효과
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--②: 사이버 엔젤 의식 몬스터가 의식 소환되었을 때 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--①: 발동시 효과 처리
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND,0,1,nil)
		and Duel.IsExistingMatchingCard(s.cafilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.mgfilter,tp,LOCATION_DECK,0,1,nil) then
		if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
			if Duel.DiscardHand(tp,aux.TRUE,1,1,REASON_COST+REASON_DISCARD,nil)==0 then return end
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g1=Duel.SelectMatchingCard(tp,s.cafilter,tp,LOCATION_DECK,0,1,1,nil)
			local g2=Duel.SelectMatchingCard(tp,s.mgfilter,tp,LOCATION_DECK,0,1,1,nil)
			g1:Merge(g2)
			if #g1>0 then
				Duel.SendtoHand(g1,tp,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,g1)
			end
		end
	end
end
function s.cafilter(c)
	return c:IsSetCard(0x2093) and c:IsAbleToHand()
end
function s.mgfilter(c)
	return c:IsSetCard(0x124) and not c:IsCode(128770113) and c:IsAbleToHand() -- 기계천사의 성소 제외
end

--②: 사이버 엔젤 의식 몬스터가 의식 소환되었을 때
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.spfilter,1,nil,tp)
end
function s.spfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x2093) and c:IsType(TYPE_RITUAL) and c:IsSummonType(SUMMON_TYPE_RITUAL) and c:IsControler(tp)
end
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x93) and (c:IsRace(RACE_WARRIOR) or c:IsRace(RACE_FAIRY))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
