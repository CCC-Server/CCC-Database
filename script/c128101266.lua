--버스터 싱크론 어웨이크 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 조건
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,1)
	c:EnableReviveLimit()

	--①: 싱크로 소환 성공 시 버스터 모드 관련 몬스터 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: 묘지에서 특수 소환 + 이름 변경
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.namecost)
	e2:SetTarget(s.nametg)
	e2:SetOperation(s.nameop)
	c:RegisterEffect(e2)
end

-- "버스터 모드" 참조
s.listed_names={CARD_ASSAULT_MODE}

---------------------------------------------------------------
-- ① 효과: 싱크로 소환 성공 시 버스터 모드 관련 몬스터 특수 소환
---------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.spfilter(c,e,tp)
	return (c:IsCode(CARD_ASSAULT_MODE) or c:ListsCode(CARD_ASSAULT_MODE))
		and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

---------------------------------------------------------------
-- ② 효과: 묘지에서 특수 소환 + 이름 변경
---------------------------------------------------------------
function s.namefilter(c)
	return c:IsType(TYPE_SYNCHRO)
end
function s.namecost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.namefilter,tp,LOCATION_EXTRA,0,1,nil) end
end
function s.nametg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
end
function s.nameop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.namefilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	Duel.ConfirmCards(1-tp,tc)

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local code=tc:GetOriginalCode()
		-- 이름 변경
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end
