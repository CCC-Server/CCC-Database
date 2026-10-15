--마계발 현세행 데스가이드 for AI
--※ cdb의 alias 칸에 10802915("마계발 현세행 데스가이드")를 입력해서
--   "이 카드명은 룰상 「마계발 현세행 데스가이드」로 취급한다"를 처리한다.
local s,id=GetID()
local CARD_TOUR_GUIDE=10802915
function s.initial_effect(c)
	--①: 패에 존재할 경우, 자신의 메인 페이즈 1 개시시에 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE_START+PHASE_MAIN1)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--①: 메인 페이즈 2 개시시 (카운트 공유)
	local e2=e1:Clone()
	e2:SetCode(EVENT_PHASE_START+PHASE_MAIN2)
	c:RegisterEffect(e2)
end
s.listed_names={CARD_TOUR_GUIDE}

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(tp)
end
--"마계발 현세행 데스가이드" 이외의 레벨 3 악마족
function s.spfilter(c,e,tp)
	return c:IsLevel(3) and c:IsRace(RACE_FIEND) and not c:IsCode(CARD_TOUR_GUIDE)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,c,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,2,tp,LOCATION_HAND|LOCATION_DECK)
	--그 효과의 발동에 대해 자신은 다른 효과를 발동할 수 없다
	Duel.SetChainLimit(s.chlimit)
end
function s.chlimit(e,rp,tp)
	return rp~=tp
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,c,e,tp)
	if #g>0 then
		g:AddCard(c)
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
