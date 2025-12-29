--헤블론-콰트로 마누스
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure
	Xyz.AddProcedure(c,nil,8,2)
	c:EnableReviveLimit()

	-- ①: 이 카드를 엑시즈 소환했을 경우에 발동할 수 있다. 자신 묘지의 카드 1장을 이 카드의 엑시즈 소재로 한다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_XYZ_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.oetg)
	e1:SetOperation(s.oeop)
	c:RegisterEffect(e1)

	-- ②: 자신 / 상대 턴에, 이 카드의 엑시즈 소재를 1개 제거하고, 상대 필드의 카드 1장을 대상으로 하여 발동할 수 있다. 그 카드를 이 카드의 엑시즈 소재로 한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_SET+TIMING_END_PHASE)
	e2:SetCost(s.xyzcost)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 묘지에서 카드 1장을 엑시즈 소재로 한다
function s.oefilter(c)
	return true
end

function s.oetg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.oefilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,nil,1,tp,LOCATION_GRAVE)
end

function s.oeop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.oefilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Overlay(c,g)
	end
end

-- ② 코스트: 엑시즈 소재 1개 제거
function s.xyzcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ② 타겟: 상대 필드의 카드 1장을 엑시즈 소재로 한다
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,g,1,0,0)
end

-- ② 처리: 상대 필드의 카드 1장을 엑시즈 소재로 한다
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,Group.FromCards(tc))
	end
end
