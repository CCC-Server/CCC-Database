local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- 이 카드명의 1턴 1장 발동 제한
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 덱에서 "네메시스 퍼펫" 몬스터를 패에 넣는 필터
function s.thfilter(c)
	return c:IsSetCard(0x763) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

-- 패에서 "네메시스 퍼펫" 몬스터를 특수 소환하는 필터
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x763) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	local isBattlePhase=(ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE)

	-- 배틀 페이즈 중이면 두 효과 전부 적용
	if isBattlePhase then
		s.doSearch(e,tp)
		s.doSpecialSummon(e,tp)
	else
		-- 배틀페이즈가 아닐 때는 하나만 선택
		local op=Duel.SelectOption(tp,
			aux.Stringid(id,0), -- "덱에서 '네메시스 퍼펫' 몬스터 1장을 패에 넣는다."
			aux.Stringid(id,1)) -- "패에서 '네메시스 퍼펫' 몬스터 1장을 특수 소환한다."
		if op==0 then
			s.doSearch(e,tp)
		else
			s.doSpecialSummon(e,tp)
		end
	end
end

-- 덱에서 패에 넣는 처리
function s.doSearch(e,tp)
	if not Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- 패에서 특수 소환 처리
function s.doSpecialSummon(e,tp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #sg>0 then
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
	end
end
