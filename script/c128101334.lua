local s,id=GetID()
function s.initial_effect(c)
	--------------------------------------
	-- ① 패/필드의 "메타파이즈" 제외 + 자신 특소 + 서치
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--------------------------------------
	-- ② 일반/특수 소환 성공 시 지속 S/T 앞면 배치
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	-- SetCategory 제거 (CATEGORY_TOFIELD 없음)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.tftg)
	e2:SetOperation(s.tfop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	--------------------------------------
	-- ③ 제외 상태 + 카드 제외되었을 때 → 제외된 "메타파이즈" 특소
	--------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_REMOVE)
	e4:SetRange(LOCATION_REMOVED)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

--------------------------------------
-- ① 비용 : 패/필드의 메타파이즈 제외
--------------------------------------
function s.rmcostfilter(c)
	return c:IsSetCard(0x105) and c:IsAbleToRemoveAsCost()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.rmcostfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmcostfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,99,nil)
	e:SetLabel(#g)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

--------------------------------------
-- ① 특소 타깃
--------------------------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

--------------------------------------
-- ① 특소 + 제거 수 / 3 만큼 서치
--------------------------------------
function s.mapfilter(c)
	return c:IsSetCard(0x105) and c:IsAbleToHand()
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	local num=math.floor(ct/3)
	if num<=0 then return end

	local g=Duel.GetMatchingGroup(s.mapfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	if #g<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=g:Select(tp,num,num,nil)
	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

--------------------------------------
-- ② 지속 S/T 필터
--------------------------------------
function s.contfilter(c)
	return c:IsSetCard(0x105)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsType(TYPE_CONTINUOUS)
		and c:IsSSetable()
end

--------------------------------------
-- ② 타깃 지정
--------------------------------------
function s.tftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.contfilter,tp,LOCATION_DECK,0,1,nil)
	end
	-- CATEGORY 없음이 정상 처리
end

--------------------------------------
-- ② 지속 S/T 앞면 배치
--------------------------------------
function s.tfop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.contfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

--------------------------------------
-- ③ 제외 상태 + 카드가 제외되었을 때
--------------------------------------
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSetCard,1,nil,0x105)
end

--------------------------------------
-- ③ 특소 타깃
--------------------------------------
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x105) and c:IsMonster() and c:IsFaceup()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_REMOVED)
end

--------------------------------------
-- ③ 제외된 몬스터 특소
--------------------------------------
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
