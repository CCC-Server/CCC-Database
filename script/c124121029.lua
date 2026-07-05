--섀터드 섀도우 블랙 머피
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 자신 / 상대 메인 페이즈에 덱에서 카드를 묘지로 보내고 링크 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE) -- 텍스트에 별도 장소 지정이 없으므로 필드 발동으로 설정
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.con1)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	
	-- ②: 드로우 이외의 방법으로 패에 넣어졌을 경우 (기존 코드 완벽 유지)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.con2)
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end
s.listed_names={CARD_POLYMERIZATION,124121029} -- 융합, 섀터드 섀도우 포에베

-- ①번 효과 조건: 자신 / 상대 메인 페이즈
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

-- ①번 효과 코스트: 덱에서 "섀터드 섀도우" 카드나 "융합" 1장을 묘지로 보냄
function s.cfil1(c)
	return (c:IsSetCard(0xfa2) or c:IsCode(CARD_POLYMERIZATION)) and c:IsAbleToGraveAsCost()
end
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfil1,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfil1,tp,LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

-- ①번 효과 타겟/오퍼레이션 필터: "섀터드 섀도우 포에베"가 현재 링크 소환 가능한가?
function s.lkfilter(c)
	return c:IsCode(124121029) and c:IsLinkSummonable(nil)
end
function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ①번 효과 처리: 포에베 링크 소환 실행
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.lkfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.LinkSummon(tp,tc,nil)
	end
end

-- =========================================================================
-- 이하 ②번 효과 관련 함수 (수정 요청에 따라 원본 100% 유지)
-- =========================================================================
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not c:IsReason(REASON_DRAW) and Duel.GetCurrentPhase()~=PHASE_DAMAGE 
end
function s.tfil2(c)
	return c:IsCode(24094653) and c:CheckActivateEffect(true,true,false)~=nil
end
function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local tg=e:GetLabelObject():GetTarget()
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tfil2,tp,LOCATION_GRAVE,0,1,nil)
	end
	e:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e:SetCategory(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.tfil2,tp,LOCATION_GRAVE,0,1,1,nil)
	local te=g:GetFirst():CheckActivateEffect(true,true,false)
	Duel.ClearTargetCard()
	e:SetProperty(te:GetProperty())
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local tg=te:GetTarget()
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end
	te:SetLabel(e:GetLabel())
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	Duel.ClearOperationInfo(0)
end
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if te:GetHandler():IsRelateToEffect(e) then
		e:SetLabel(te:GetLabel())
		e:SetLabelObject(te:GetLabelObject())
		local op=te:GetOperation()
		if op then
			op(e,tp,eg,ep,ev,re,r,rp)
		end
		te:SetLabel(e:GetLabel())
		te:SetLabelObject(e:GetLabelObject())
	end
end