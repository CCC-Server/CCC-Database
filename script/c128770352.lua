local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 조건: 튜너 + 튜너 이외의 "요정향" 1장 이상
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x767),1,99)
	c:EnableReviveLimit()

	---------------------------------------------
	-- ①: 싱크로 소환 성공 시 서치
	---------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	---------------------------------------------
	-- ②: 몬스터 소환 / 효과 발동에 대응 → 무효 + 토큰
	---------------------------------------------
	-- 몬스터 효과 대응
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- 소환 대응 (일반/반전/특수)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_SUMMON)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.summoncon)
	e3:SetTarget(s.summontg)
	e3:SetOperation(s.summonop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_FLIP_SUMMON)
	c:RegisterEffect(e4)
	local e5=e3:Clone()
	e5:SetCode(EVENT_SPSUMMON)
	c:RegisterEffect(e5)
end

---------------------------------------------------
-- ①: 싱크로 소환 성공 시 "요정향" 카드 서치
---------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.thfilter(c)
	return c:IsSetCard(0x767) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

---------------------------------------------------
-- ②-1: 몬스터 효과 무효 → 묘지 → 토큰
---------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainDisablable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_MZONE)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.SendtoGrave(eg,REASON_EFFECT)
		s.tokenop(tp)
	end
end

---------------------------------------------------
-- ②-2: 소환 무효 → 묘지 → 토큰
---------------------------------------------------
function s.summoncon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp
end
function s.summontg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_MZONE)
end
function s.summonop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateSummon(eg:GetFirst())
	Duel.SendtoGrave(eg,REASON_EFFECT)
	s.tokenop(tp)
end

---------------------------------------------------
-- 공통 처리: 상대 필드에 "요정향 토큰" 생성
---------------------------------------------------
function s.tokenop(tp)
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,128770345,0x767,TYPES_TOKEN+TYPE_TUNER,1600,1000,4,RACE_SPELLCASTER,ATTRIBUTE_WIND,1-tp) then return end
	local token=Duel.CreateToken(tp,128770345)
	Duel.SpecialSummon(token,0,1-tp,1-tp,false,false,POS_FACEUP)
end
