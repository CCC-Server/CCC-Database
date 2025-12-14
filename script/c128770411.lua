--가제트 트리뷰트 엔진
local s,id=GetID()
function s.initial_effect(c)
	--①: 레벨 4 이하 가제트가 드로우 이외로 패에 들어왔을 때 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.sumcon)
	e1:SetTarget(s.sumtg)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)

	--②: 패의 레벨6 이상 가제트 몬스터 일반 소환 (자신/상대 턴)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMING_MAIN_END+TIMING_BATTLE_PHASE)
	e2:SetTarget(s.sumtg2)
	e2:SetOperation(s.sumop2)
	c:RegisterEffect(e2)
end

--------------------------------------------------
--①: 드로우 이외로 패에 들어온 레벨4 이하 가제트 → 일반 소환
--------------------------------------------------
function s.cfilter(c,tp)
	return c:IsControler(tp) and c:IsSetCard(0x51) and c:IsLevelBelow(4)
		and not c:IsReason(REASON_DRAW) and c:IsSummonable(true,nil)
end
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.cfilter,1,nil,tp) end
	Duel.SetTargetCard(eg)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.cfilter,nil,tp):Filter(Card.IsRelateToEffect,nil,e)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
		-- 그 턴, 엑스트라 덱 특수 소환 금지
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.splimit(e,c)
	return c:IsLocation(LOCATION_EXTRA)
end

--------------------------------------------------
--②: 패의 레벨6 이상 가제트 몬스터 일반 소환 (자신/상대 턴)
--------------------------------------------------
function s.sumfilter2(c)
	return c:IsSetCard(0x51) and c:IsLevelAbove(6) and c:IsSummonable(true,nil)
end
function s.sumtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.sumfilter2,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,tp,LOCATION_HAND)
end
function s.sumop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sumfilter2,tp,LOCATION_HAND,0,1,1,nil)
	if #g>0 then
		Duel.Summon(tp,g:GetFirst(),true,nil)
	end
end
