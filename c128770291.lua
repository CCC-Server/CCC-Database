--스펠크래프트 차원여왕
local s,id=GetID()
function s.initial_effect(c)
	--이 카드명의 카드는 1턴에 1장만 발동 가능
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--발동 조건: 가마솥에 마력카운터 21개 이상
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(s.cauldron,tp,LOCATION_SZONE,0,nil)
	return tc and tc:GetCounter(0x1)>=21
end
function s.cauldron(c)
	return c:IsFaceup() and c:IsCode(128770286) -- 스펠크래프트 마녀의 가마솥
end

--코스트: 없음 (패를 되돌리기 때문에 따로 필요 X)
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end

--대상 설정
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,5)
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,5)
end

--발동 효과
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.BreakEffect()
	Duel.Draw(tp,5,REASON_EFFECT)

	--통상 소환 3회 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetValue(2)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	--"스펠크래프트 종막의 죄 사탄" 특수 소환
	local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if tc then
		-- 오버디멘션 효과처럼 처리해서 splimit 통과시키기
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_SET_PROC)
		tc:RegisterEffect(e2)
		Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,0) --표식
	end
end

function s.spfilter(c,e,tp)
	return c:IsCode(128770278) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
