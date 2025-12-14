--네메시스 아티팩트 제네시스 서치
local s,id=GetID()
function s.initial_effect(c)
	--이 카드명의 카드는 1턴에 1장만 발동 가능
	c:SetUniqueOnField(1,0,id)

	--① 효과: "네메시스 아티팩트" 몬스터 서치 또는 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,1}) --① 효과 1턴에 1번
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

-------------------------------------
--①: 덱에서 "네메시스 아티팩트" 몬스터 1장 서치 or 특소
-------------------------------------
function s.thfilter(c,e,tp)
	return c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
		and (c:IsAbleToHand() or (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then return end
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		--특수 소환 선택 시
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	else
		--그 외엔 패로 추가
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
