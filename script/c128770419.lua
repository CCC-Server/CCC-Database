local s,id=GetID()
function s.initial_effect(c)
	-- ① Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ② Special Summon from Deck (Main/Battle Phase) + Extra Deck restriction
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.phasecon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- ③ Xyz Summon on attack declaration
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,id+200)
	e3:SetOperation(s.xyzop)
	c:RegisterEffect(e3)
end

-- ① Special Summon condition
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		or Duel.IsExistingMatchingCard(s.swk,tp,LOCATION_MZONE,0,1,nil)
end

-- ② Main Phase or Battle Phase check
function s.phasecon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph==PHASE_BATTLE
end

-- ② Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- ② Special Summon operation + Extra Deck restriction
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end

	-- Extra Deck restriction
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.exlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- Extra Deck summon limit
function s.exlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0x770)
end

function s.xyzfilter(c,tp,mg)
	return c:IsSetCard(0x770)
		and c:IsType(TYPE_XYZ)
		and c:IsXyzSummonable(mg)
end

-- ③ Xyz Summon operation
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- 엑스트라 덱 공간 체크
	if Duel.GetLocationCountFromEx(tp)<=0 then return end

	-- 필드의 몬스터들을 소재 후보로
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)

	-- 이 카드가 필드에 있어야 함
	if not c:IsRelateToEffect(e) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(
		tp,
		s.xyzfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		1,
		nil,
		tp,
		mg
	)

	local sc=g:GetFirst()
	if sc then
		Duel.XyzSummon(tp,sc,mg)
	end
end
