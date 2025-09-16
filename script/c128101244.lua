-- Holophantasy Synchro Lv6 (Custom)
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환
	c:EnableReviveLimit()
	-- 튜너 1 + 비튜너 1, 단 이 카드의 싱크로에 한해 자신 필드의 "홀로판타지"를 튜너로 취급
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,1,s.matfilter)

	-- ① 싱크로 소환 성공시: 덱에서 "홀로판타지" 카드 1장 서치 (하드 OPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) end)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ② (지속) 조건 달성시: 자신 필드의 "홀로판타지" 몬스터 ATK +1000
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(function(e,tc) return tc:IsSetCard(0xc44) end)
	e2:SetCondition(s.atkcon)
	e2:SetValue(1000)
	c:RegisterEffect(e2)

	-- ③ 퀵: 자신/상대 턴, 자신을 엑스트라로 되돌리고 → GY의 "홀로판타지" 2장 특소 후, 선택 파괴 (하드 OPT)
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

-- 세트 등록
s.listed_series={0xc44}

-------------------------------------------------
-- 싱크로: 추가 소재 필터(튜너 취급)
-------------------------------------------------
-- 이 카드의 싱크로 소환 시, 자신 필드의 "홀로판타지"를 튜너로 취급
function s.matfilter(c,sc,sumtype,tp)
	return c:IsSetCard(0xc44,sc,sumtype,tp) and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
end

-------------------------------------------------
-- ① 싱크로 성공시 서치
-------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc44) and c:IsAbleToHand()
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

-------------------------------------------------
-- ② ATK +1000 지속 오라 (필드/묘지 합계 필드 마법 3장 이상)
-------------------------------------------------
local function count_fieldspells()
	-- 양쪽 필드존(보통 앞면), 양쪽 묘지의 필드 마법 총합
	local ct=0
	local f1=Duel.GetMatchingGroup(Card.IsType,0,LOCATION_FZONE,LOCATION_FZONE,nil,TYPE_FIELD)
	local gy=Duel.GetMatchingGroup(Card.IsType,0,LOCATION_GRAVE,LOCATION_GRAVE,nil,TYPE_FIELD)
	ct=ct+#f1+#gy
	return ct
end
function s.atkcon(e)
	local c=e:GetHandler()
	return c:IsFaceup() and c:IsLocation(LOCATION_MZONE) and count_fieldspells()>=3
end

-------------------------------------------------
-- ③ 퀵: 자신을 엑스트라로 되돌리고 → GY의 "홀로판타지" 2장 특소 → 선택 파괴
-------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc44) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	-- Extra로 되돌림(EDOPro에서 Extra 소속 카드는 SendtoDeck로 처리)
	Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_COST)
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
