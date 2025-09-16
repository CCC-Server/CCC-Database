-- Holophantasy Synchro Lv6 (Custom)
-- "홀로판타지" 튜너 + 튜너 이외의 몬스터 1장
-- 이 카드를 싱크로 소환할 경우, 자신 필드의 "홀로판타지" 1장을 튜너로 취급할 수 있다.
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 절차
	c:EnableReviveLimit()
	-- Cyber Slash 방식: 이 카드의 싱크로 소환 시 자신 필드의 "홀로판타지"를 튜너로 취급
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,1,s.matfilter)

	-- ① 상대가 카드의 효과를 발동했을 때, 필드의 카드 1장 파괴 / 필드존에 카드가 있으면 대신 제외 (하드 OPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- ② 필드/묘지에 필드마법 3장 이상이면 전투/효과로 파괴되지 않음
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.indcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e2b)

	-- ③ 퀵: 자신을 엑스트라로 되돌리고 → GY의 "홀로판타지" 2장 특소 후, 선택 파괴 (하드 OPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMING_END_PHASE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end
s.listed_series={0xc44}

-------------------------------------------------
-- 싱크로 추가 소재 필터(튜너 취급)
-------------------------------------------------
function s.matfilter(c,sc,sumtype,tp)
	-- 자신 필드의 "홀로판타지"라면, 이 카드의 싱크로 소환에 한해 튜너로도 취급
	return c:IsSetCard(0xc44,sc,sumtype,tp) and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
end

-------------------------------------------------
-- ① 상대가 카드의 효과를 발동했을 때
-------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp -- 상대가 발동했을 때만
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	-- 파괴/제외 둘 다 가능한 정보로 표기
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	-- 필드존에 카드가 1장 이상 존재하면, 그 카드를 "제외"로 처리
	local fzone_ct=Duel.GetMatchingGroupCount(Card.IsOnField,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	if fzone_ct>0 then
		-- 제외 시도 (텍스트상 파괴 대신 제외)
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	else
		-- 평소엔 파괴
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-------------------------------------------------
-- ② 파괴 내성 조건: 필드/묘지의 필드마법 총 3장 이상
-------------------------------------------------
local function count_fieldspells()
	local ct=0
	local fz=Duel.GetMatchingGroup(Card.IsType,0,LOCATION_FZONE,LOCATION_FZONE,nil,TYPE_FIELD)
	local gy=Duel.GetMatchingGroup(Card.IsType,0,LOCATION_GRAVE,LOCATION_GRAVE,nil,TYPE_FIELD)
	ct=#fz+#gy
	return ct
end
function s.indcon(e)
	return count_fieldspells()>=3
end

-------------------------------------------------
-- ③ 퀵: 자신을 엑스트라로 되돌리고 → "홀로판타지" 2체 특소 → 선택 파괴
-------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc44) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_COST) -- 엑스트라로 되돌림(EDOPro 표준 처리)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,2,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,2,2,nil,e,tp)
	if #g<2 then return end
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 선택적으로 필드 1장 파괴
		local dg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=dg:Select(tp,1,1,nil)
			if #sg>0 then
				Duel.HintSelection(sg,true)
				Duel.Destroy(sg,REASON_EFFECT)
			end
		end
	end
end
