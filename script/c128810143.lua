--헤블론-콰트로 마누스
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure
	Xyz.AddProcedure(c,nil,8,2)
	c:EnableReviveLimit()

	-- ①: 엑시즈 소환 성공 시 묘지 자원 흡수
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	-- [수정] CATEGORY_TOHAND 삭제 (소재로 넣는 것은 패에 넣는 것이 아님)
	-- 굳이 표시하자면 묘지에서 떠나므로 CATEGORY_LEAVE_GRAVE 정도는 가능하나, 없어도 무방합니다.
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_XYZ_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.oetg)
	e1:SetOperation(s.oeop)
	c:RegisterEffect(e1)

	-- ②: 프리 체인 상대 카드 흡수
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	-- [수정] CATEGORY_TOHAND 삭제
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
	-- [수정] CATEGORY_TOHAND 정보 삭제
	if chk==0 then return Duel.IsExistingMatchingCard(s.oefilter,tp,LOCATION_GRAVE,0,1,nil) end
end

function s.oeop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL) -- 힌트 메시지를 소재 선택으로 변경
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
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL) -- 힌트 메시지 변경
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	-- [수정] SetOperationInfo에서 CATEGORY_TOHAND 삭제. 소재로 넣는 것은 별도 카테고리가 없음.
end

-- ② 처리: 상대 필드의 카드 1장을 엑시즈 소재로 한다
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		-- 상대 몬스터를 소재로 할 때는 룰상 몬스터여야 하거나, Overlay 함수가 처리해 줌
		-- Group.FromCards(tc) 대신 그냥 tc를 넣어도 되지만 Group이 안전함
		Duel.Overlay(c,Group.FromCards(tc))
	end
end