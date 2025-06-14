-- 헤르모스를 잇는 계약 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- 효과 ① : 융합 몬스터 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 효과 ② : 묘지에서 패로 회수
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- #######################
-- 융합 몬스터 소환 처리

s.listed_names={46232525} -- "헤르모스의 발톱"

function s.fusfilter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:ListsCode(46232525)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
		and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil,c:GetRace())
end

function s.matfilter(c,race)
	return c:IsRace(race) and c:IsAbleToDeck()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local fc=g:GetFirst()
	if not fc then return end
	local race=fc:GetRace()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local mg=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil,race)
	if #mg==0 then return end
	if Duel.SendtoDeck(mg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.SpecialSummon(fc,0,tp,tp,true,true,POS_FACEUP)
	end
end

-- #######################
-- 묘지에서 패로 회수

function s.hermosfilter(c)
	return c:IsFaceup() and c:ListsCode(46232525) and c:IsType(TYPE_MONSTER)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.hermosfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
