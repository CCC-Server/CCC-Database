-- Holophantasy Synchro Lv6 (Custom)
-- "홀로판타지" 튜너 + 튜너 이외의 몬스터 1장
-- 이 카드를 싱크로 소환할 경우, 자신 필드의 "홀로판타지" 1장을 튜너로 취급할 수 있다.
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 절차
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,1,s.matfilter)

	-- ① 싱크로 소환 성공시: GY의 "홀로판타지" 카드 1장 회수 (하드 OPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) end)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ② (지속) 자신 필드/묘지에 필드 마법 3장 이상이면, 배틀 페이즈 중 상대는 효과 발동 불가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.lockcon)
	e2:SetValue(function(e,re,tp) return true end)
	c:RegisterEffect(e2)

	-- ③ 퀵: 자신을 엑스트라로 되돌리고 → GY의 "홀로판타지" 2장 특소 후, 선택 파괴 (하드 OPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	-- 항상 프리체인 힌트(상대 턴 포함)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end
s.listed_series={0xc44}

-------------------------------------------------
-- 싱크로: 추가 소재 필터(튜너 취급)
-------------------------------------------------
function s.matfilter(c,sc,sumtype,tp)
	return c:IsSetCard(0xc44,sc,sumtype,tp) and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
end

-------------------------------------------------
-- ① 싱크로 성공시: GY의 "홀로판타지" 1장 회수
-------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc44) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-------------------------------------------------
-- ② 배틀 페이즈 락 조건
-------------------------------------------------
local function count_self_fieldspells(tp)
	local ct=0
	ct=ct+Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_FZONE,0,nil,TYPE_FIELD)
	ct=ct+Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_FIELD)
	return ct
end
function s.lockcon(e)
	local ph=Duel.GetCurrentPhase()
	if ph<PHASE_BATTLE_START or ph>PHASE_BATTLE then return false end
	return count_self_fieldspells(e:GetHandlerPlayer())>=3
end

-------------------------------------------------
-- ③ 특소/파괴
-------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc44) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
-- 코스트: 자신을 엑스트라로 되돌림
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_COST)
end
-- 이 카드가 코스트로 빠진 '뒤' 남는 칸 기준으로 체크
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ft=Duel.GetMZoneCount(tp,e:GetHandler())
		return ft>=2
			and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
			and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,2,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
	-- 코스트 처리 후 실제 남은 칸 재확인
	if Duel.GetMZoneCount(tp,nil)<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,2,2,nil,e,tp)
	if #g<2 then return end
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		local dg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=dg:Select(tp,1,1,nil)
			if #sg>0 then
				Duel.HintSelection(sg,true)
				Duel.Destroy(sg,REASON_EFFECT)
			end
		end
	end
end
