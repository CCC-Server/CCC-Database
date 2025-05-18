-- A・O・J 인필트레이터 셰이드
local s,id=GetID()
function s.initial_effect(c)
	-- ① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- ② 특수 소환 성공 시 상대 묘지 몬스터를 전부 빛 속성으로 변경
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetOperation(s.attrchange)
	c:RegisterEffect(e2)

	-- ③ 싱크로 소환 (퀵)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.syntg)
	e3:SetOperation(s.synop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_ALLY_OF_JUSTICE}

-- ■ ① 조건: 필드에 A.O.J 몬스터 2장 이상
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,SET_ALLY_OF_JUSTICE)>=2
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ■ ② 상대 묘지 몬스터 속성 변경
function s.attrchange(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsLocation,tp,0,LOCATION_GRAVE,nil)
	for tc in g:Iter() do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e1:SetValue(ATTRIBUTE_LIGHT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		tc:RegisterEffect(e1)
	end
end

-- ■ ③ 퀵 싱크로: 이 카드와 필드의 몬스터 1장으로 기계족 싱크로 소환
function s.synfilter(c,sc,tp)
	return Duel.IsExistingMatchingCard(s.syncand,tp,LOCATION_EXTRA,0,1,nil,sc,c,tp)
end
function s.syncand(sc,c1,c,tp)
	return sc:IsRace(RACE_MACHINE)
		and Duel.GetLocationCountFromEx(tp,tp,Group.FromCards(c1,c),sc)>0
		and sc:IsSynchroSummonable(nil,Group.FromCards(c1,c))
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_MZONE,0,1,c)
			and Duel.IsExistingMatchingCard(s.syncand,tp,LOCATION_EXTRA,0,1,nil,c,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,c)
end
function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or not tc or not tc:IsRelateToEffect(e) then return end
	local mg=Group.FromCards(c,tc)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,function(sc) return s.syncand(sc,tc,c,tp) end,tp,LOCATION_EXTRA,0,1,1,nil)
	local sc=g:GetFirst()
	if sc then
		Duel.SynchroSummon(tp,sc,nil,mg)
	end
end
