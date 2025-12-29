--헤블론-레드 크라운
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_LIGHT+ATTRIBUTE_DARK),4,2)
	c:EnableReviveLimit()

	-- ①: 엑시즈 소환 시 덱에서 소재 충전
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_XYZ_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.oetg)
	e1:SetOperation(s.oeop)
	c:RegisterEffect(e1)

	-- ②: 소재 제거 시 묘지 소생
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) -- FIELD 타입으로 변경
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE_OVERLAY) -- 소재 제거 이벤트
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 처리
function s.oefilter(c)
	return c:IsSetCard(0xc06) and c:IsType(TYPE_MONSTER)
end
function s.oetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.oefilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.oeop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.oefilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end

-- ② 조건: 제거된 카드가 "이 카드"의 소재였는지 확인
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- eg에 있는 카드 중 하나라도 이전 위치가 오버레이고, 이전 호스트가 이 카드일 때
	return eg:IsExists(function(tc) return tc:IsPreviousLocation(LOCATION_OVERLAY) and tc:GetReasonCard()==c end, 1, nil)
	-- 참고: GetReasonCard()는 코스트/효과로 제거한 주체를 반환합니다. 이 카드의 효과/코스트로 제거된 경우 작동합니다.
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc06) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end