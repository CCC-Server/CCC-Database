-- A・O・J 시뮬레이터
local s,id=GetID()
function s.initial_effect(c)
	-- ① 패에서 묘지로 보내고 싱크로 + 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.sscost)
	e1:SetTarget(s.sstg)
	e1:SetOperation(s.ssop)
	c:RegisterEffect(e1)

	-- ② 다음 턴 스탠바이 페이즈에 패로 되돌림
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- ③ 묘지로 간 턴 추적용
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)
end

-- ■ ① 비용: 패에서 묘지
function s.sscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

-- ■ ① 싱크로 타겟 조건
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
		return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end

-- 기계족 싱크로 조건
function s.synfilter(c,mg)
	return c:IsRace(RACE_MACHINE) and c:IsType(TYPE_SYNCHRO) and c:IsSynchroSummonable(nil,mg)
end

-- ■ ① 싱크로 + 파괴
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local sg=Duel.GetMatchingGroup(s.synfilter,tp,LOCATION_EXTRA,0,nil,mg)
	if #sg==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=sg:Select(tp,1,1,nil):GetFirst()
	if not sc then return end

	Duel.SynchroSummon(tp,sc,nil,mg)

	-- 싱크로 성공 후 파괴
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local dg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

-- ■ ② 다음 턴 회수용 플래그
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
end

-- ■ ② 다음 턴 스탠바이 시 회수
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and e:GetHandler():GetFlagEffect(id)>0
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end
