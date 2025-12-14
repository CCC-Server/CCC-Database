local s,id=GetID()
function s.initial_effect(c)
	-- ① Reveal "수왕권사-배트" → Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ② Battle Phase start: negate opponent monster effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetOperation(s.bpnegop)
	c:RegisterEffect(e2)

	-- ③ Xyz Summon on attack declaration
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,id+200)
	e3:SetOperation(s.xyzop)
	c:RegisterEffect(e3)
end

-- --------------------
-- Filters
-- --------------------
function s.swk(c)
	return c:IsSetCard(0x770)
end

function s.deckspfilter(c,e,tp)
	return c:IsSetCard(0x770)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.revealfilter(c)
	return c:IsCode(128770430) -- "수왕권사-배트" 실제 카드 ID로 변경
end

function s.xyzfilter(c,tp)
	return c:IsSetCard(0x770)
		and c:IsType(TYPE_XYZ)
		and c:IsXyzSummonable(nil)
end

-- --------------------
-- ① Special Summon
-- --------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and Duel.IsExistingMatchingCard(s.revealfilter,tp,LOCATION_EXTRA,0,1,nil)
			and Duel.IsExistingMatchingCard(s.deckspfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local rg=Duel.SelectMatchingCard(tp,s.revealfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #rg==0 then return end
	Duel.ConfirmCards(1-tp,rg)

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end

	Duel.SpecialSummon(e:GetHandler(),0,tp,tp,false,false,POS_FACEUP)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.deckspfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.exlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.exlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0x770)
end

-- --------------------
-- ② Battle Phase negation
-- --------------------
function s.bpnegop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetTargetRange(0,LOCATION_MZONE)
	e1:SetTarget(s.negfilter)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	Duel.RegisterEffect(e2,tp)
end

function s.negfilter(e,c)
	local bc=c:GetBattleTarget()
	return bc and bc:IsSetCard(0x770)
end

-- --------------------
-- ③ Xyz Summon
-- --------------------
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

