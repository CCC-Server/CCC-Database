local s,id=GetID()
function s.initial_effect(c)
	-- ① Special Summon when added to hand except by draw
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- ② Add "수왕권사" Spell from Deck to hand
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.phasecon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- ③ Xyz Summon on attack declaration
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,{id,2})
	e3:SetOperation(s.xyzop)
	c:RegisterEffect(e3)
end

-- --------------------
-- Filters
-- --------------------
function s.swk_spell(c)
	return c:IsSetCard(0x770) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.xyzfilter(c,tp)
	return c:IsSetCard(0x770)
		and c:IsType(TYPE_XYZ)
		and c:IsXyzSummonable(nil)
end

-- --------------------
-- ① Special Summon condition (not by draw)
-- --------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return not (r & REASON_DRAW)~=0
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- --------------------
-- ② Phase check (Main or Battle Phase)
-- --------------------
function s.phasecon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph==PHASE_BATTLE
end

-- --------------------
-- ② Search Spell
-- --------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.swk_spell,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.swk_spell,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
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

