local s,id=GetID()
function s.initial_effect(c)
	-- ①: 패의 이 카드를 "TG" 싱크로 몬스터의 소재로 할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_SYNCHRO_MAT_FROM_HAND)
	e1:SetRange(LOCATION_HAND)
	e1:SetValue(s.synval)
	c:RegisterEffect(e1)
	
	-- ②: 싱크로 소재로 할 경우, 이 카드를 튜너 이외의 몬스터(비튜너)로 취급할 수 있다.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_NONTUNER) -- 휠 싱크론과 동일한 코드 적용
	e2:SetRange(LOCATION_MZONE+LOCATION_HAND)
	c:RegisterEffect(e2)
	
	-- ③: 싱크로 소재로 묘지로 보내졌을 경우 덱에서 특소
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- ① 패 싱크로 대상 체크
function s.synval(e,mc,sc)
	return sc:IsSetCard(0x27)
end

-- ③ 리쿠르트 효과 조건 및 처리
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_SYNCHRO
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x27) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end