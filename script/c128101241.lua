--Holophantasy Custom 3
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환 + 필드존 카드 묘지
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(TIMING_MAIN_END)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--② 소환 성공시 덱/묘지 특소 + 상대 턴 "이 카드가 특수 소환되어 있었다면" 자신 포함, 자신 필드만으로 싱크로
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end
s.listed_series={0xc44}

----------------------------------------
--① 패 특소 + 필드존 카드 묘지
----------------------------------------
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.tgfilter(c)
	return c:IsFaceup() and c:IsAbleToGrave()
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_FZONE) and s.tgfilter(chkc) end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.SendtoGrave(tc,REASON_EFFECT)>0 and c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

----------------------------------------
--② 소환 성공시 특소 + (상대 턴 특소 상태였으면) 자신 포함 싱크로
----------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc44) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g==0 then return end
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)<=0 then return end

	-- ★ 여기 수정 포인트 ★
	-- 조건: "상대 턴"이고, 이 카드가 "특수 소환된 상태"여야 함
	if Duel.GetTurnPlayer()==tp then return end
	if not (c:IsLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_SPECIAL)) then return end

	-- 자신 필드 앞면 몬스터만 소재 풀
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)

	-- 엑스트라에서, '이 카드(c)'를 반드시 포함해 싱크로 소환 가능하고, 세트 0xc44인 후보만
	local sg=Duel.GetMatchingGroup(function(sc,smat,matgrp)
		return sc:IsSetCard(0xc44) and sc:IsSynchroSummonable(smat,matgrp)
	end,tp,LOCATION_EXTRA,0,nil,c,mg)

	if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=sg:Select(tp,1,1,nil):GetFirst()
		if sc then
			-- 반드시 자신(c)을 포함해, 자신 필드 풀(mg)로 싱크로 소환
			Duel.SynchroSummon(tp,sc,c,mg)
		end
	end
end
