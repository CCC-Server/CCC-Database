-- 올마이티 셀레스티얼 타이탄- 이터니티 크리에이터
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- 싱크로 소환 조건 (오류 해결 지점)
	-- 튜너 4장 / 비튜너(천사족+싱크로) 1장
	Synchro.AddProcedure(c,nil,4,4,Synchro.NonTunerEx(s.matfilter),1,1)
	c:AddMustBeSynchroSummoned()
	Pendulum.AddProcedure(c,false)
	
	
	-- ①: 발동한 효과를 받지 않음
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
	
	-- ②: 덱으로 되돌리고 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc02}
s.listed_names={128810052}
s.synchro_nt_required=1
-- 수정된 소재 필터: 5번째 인자(nil) 문제를 피하기 위해 기본형으로 작성
function s.matfilter(c)
	return c:IsRace(RACE_FAIRY) and c:IsType(TYPE_SYNCHRO)
end

function s.efilter(e,te)
    -- 효과를 발동한 카드(Owner)가 이 카드(e:GetHandler)가 아닐 것
    -- 그리고 그 효과가 '발동한' 효과(IsActivated)일 것
    return te:GetOwner()~=e:GetHandler() and te:IsActivated()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeck() end
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,nil)
	g:AddCard(c)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spfilter(c,e,tp)
	return c:IsCode(128810052) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)	
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsAbleToDeck() then return end
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,nil)
	g:AddCard(c)
	if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		local og=Duel.GetOperatedGroup()
		if og:IsContains(c) then
			local sg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
			if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sc=sg:Select(tp,1,1,nil):GetFirst()
				if sc and Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
					sc:CompleteProcedure()
				end
			end
		end
	end
end