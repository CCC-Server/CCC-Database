--Support Monster for Horus the Black Flame Dragon
local s,id=GetID()
function s.initial_effect(c)
	--①: 소환 성공 시 서치 (Search)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	--②: 자신 메인 페이즈에 릴리스하고 특소 (Ignition)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1) -- ②번 효과 제약 공유
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--②: 상대 마법 발동 시 필드에서 릴리스하고 특소 (Quick - Field)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1) -- ②번 효과 제약 공유
	e3:SetCondition(s.spcon_magic)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	--③: 상대 마법 효과 발동 "경우" 패에서 릴리스하고 특소 (Trigger - Hand)
	--타이밍: "때"가 아닌 "경우"이므로 체인 처리가 끝난 후 발동 (EVENT_CHAIN_SOLVED 사용)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) -- 유발 효과로 변경
	e4:SetProperty(EFFECT_FLAG_DELAY) -- 딜레이 허용 ("경우")
	e4:SetCode(EVENT_CHAIN_SOLVED)    -- 효과 처리 직후 타이밍 감지
	e4:SetRange(LOCATION_HAND)
	--e4:SetCountLimit(1,id+2) -- ③번 효과 횟수 제약 필요 시 주석 해제
	e4:SetCondition(s.spcon_magic_trigger)
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- "호루스의 흑염룡" 세트 코드: 0x1003
s.listed_series={0x1003}

-- ①: 서치 필터
function s.thfilter(c)
	return c:IsSetCard(0x1003) and c:IsAbleToHand() and not c:IsCode(id)
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

-- ②: 조건 (상대가 마법 카드의 효과를 발동했을 때 - 체인)
function s.spcon_magic(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_SPELL)
end

-- ③: 조건 (상대가 마법 카드의 효과를 발동했을 경우 - 처리 후 유발)
function s.spcon_magic_trigger(e,tp,eg,ep,ev,re,r,rp)
	-- re: 처리된 효과, rp: 발동 플레이어
	return rp==1-tp and re:IsActiveType(TYPE_SPELL)
end

-- 공통 코스트 (이 카드를 릴리스)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

-- 공통 특수 소환 필터 (레벨 6 이하 "호루스의 흑염룡")
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x1003) and c:IsLevelBelow(6) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- 공통 타겟 지정
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetMZoneCount(tp,e:GetHandler())>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-- 공통 효과 처리
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end