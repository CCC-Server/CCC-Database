-- 헤블론-콰트로 마누스
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환 절차: 레벨 8 몬스터 × 2
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsLevel,8),2)
	c:EnableReviveLimit()

	-- ① 엑시즈 소환 성공시: 묘지의 카드 1장을 소재로 한다
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.matcon)
	e1:SetTarget(s.mattg)
	e1:SetOperation(s.matop)
	c:RegisterEffect(e1)

	-- ② 자신/상대 턴: 소재 1개 제거 → 상대 필드의 카드 1장을 소재로 한다
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCost(s.xcost)
	e2:SetTarget(s.xtg)
	e2:SetOperation(s.xop)
	c:RegisterEffect(e2)
end

-- ① 조건: 이 카드가 엑시즈 소환되었을 경우
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

-- 소재 필터 수정: 메서드 호출 방식으로 안전하게 변경
function s.matfilter(c,tp)
	return c:IsCanBeXyzMaterial(xyzc,tp,REASON_EFFECT)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_GRAVE,0,1,nil,e:GetHandler(),tp) end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,0)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsImmuneToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end

-- ② 코스트: 엑시즈 소재 1개 제거
function s.xcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ② 효과 필터 추가 (IsAbleToOverlay 오류 해결을 위함)
function s.ovfilter(c,tp)
	return c:IsOnField() and c:IsControler(1-tp) and c:IsAbleToOverlay(tp)
end

-- 대상: 상대 필드의 카드 1장
function s.xtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return s.ovfilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.ovfilter,tp,0,LOCATION_ONFIELD,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.ovfilter,tp,0,LOCATION_ONFIELD,1,1,nil,tp)
end

-- 처리: 그 카드를 이 카드의 소재로 한다
function s.xop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		if tc:IsType(TYPE_TOKEN) then return end
		Duel.Overlay(c,tc)
	end
end