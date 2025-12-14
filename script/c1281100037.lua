-- 파괴수대결전 - 파이널 워즈
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터
function s.initial_effect(c)
	-- 카운터 설정 (종류 및 최대 개수 10개)
	c:EnableCounterPermit(COUNTER_KAIJU)
	c:SetCounterLimit(COUNTER_KAIJU,10)
	
	-- 발동
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	
	-- ①: 카운터 놓기 (특수 소환 시)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	-- ②: 소생 (기동 / 유발)
	-- 자신 메인 페이즈 (기동)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id) -- ② 효과 통합 1턴에 1번
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	-- 상대 소환 시 (유발)
	local e3=e2:Clone()
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3:SetCondition(s.spcon_trig)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- ③: 서치 (기동 / 유발)
	-- 자신 메인 페이즈 (기동)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCountLimit(1,{id,2})
	e5:SetCost(s.thcost)
	e5:SetTarget(s.thtg)
	e5:SetOperation(s.thop)
	c:RegisterEffect(e5)
	-- 상대 효과 발동 시 (유발)
	local e6=e5:Clone()
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_CHAINING)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCondition(s.thcon_trig)
	c:RegisterEffect(e6)
end
s.listed_series={0xc82, 0xd3} -- 대괴수결전병기, 파괴수
s.counter_place_list={COUNTER_KAIJU} -- 카운터를 놓는 리스트

-- ① 효과: 카운터 조건 확인
function s.ctfilter(c,tp)
	-- "파괴수" 몬스터 또는 상대 필드에 특수 소환된 몬스터
	return c:IsFaceup() and (c:IsSetCard(0xd3) or c:IsControler(1-tp))
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	-- SetCounterLimit가 설정되어 있으므로 개수 초과 체크 불필요
	if eg:IsExists(s.ctfilter,1,nil,tp) then
		e:GetHandler():AddCounter(COUNTER_KAIJU,1)
	end
end

-- ② 효과: 조건 (상대 소환 시)
function s.spcon_trig(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsControler,1,nil,1-tp)
end
-- ② 효과: 타겟 (묘지의 Lv5 이상 대괴수 or 파괴수)
function s.spfilter(c,e,tp)
	return c:IsLevelAbove(5) and (c:IsSetCard(0xc82) or c:IsSetCard(0xd3))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ③ 효과: 조건 (상대 효과 발동 시)
function s.thcon_trig(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp -- 상대가 발동했을 때
end
-- ③ 효과: 코스트 (카운터 3개 제거)
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 중요 수정: 1, 1 (덱) -> LOCATION_ONFIELD, LOCATION_ONFIELD (필드)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_KAIJU,3,REASON_COST) end
	Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_KAIJU,3,REASON_COST)
end
-- ③ 효과: 서치 필터
function s.thfilter(c)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsCode(id) and c:IsAbleToHand()
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