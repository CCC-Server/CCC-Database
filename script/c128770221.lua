--스파클 아르카디아 ○○
local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드명의 카드는 1턴에 1장밖에 발동할 수 없음 (OATH)
	-- ① 덱에서 '스파클 아르카디아' 몬스터 1장 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- 카드 자체 1장/턴
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- ② 묘지에서 제외하여, 레벨 합계에 맞는 '스파클 아르카디아' 싱크로 몬스터를 싱크로 소환 취급 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- 이 효과 1턴 1번
	e2:SetCost(aux.bfgcost) -- 묘지의 이 카드를 제외
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)
end

-----------------------------------
-- ① 효과
-----------------------------------
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.spdeckfilter(c,e,tp)
	return c:IsSetCard(0x760) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spdeckfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spdeckfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		-- 싱크로 몬스터만 엑스트라에서 특수 소환 가능
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(function(_,c) return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_SYNCHRO) end)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		aux.addTempLizardCheck(e:GetHandler(),tp,function(_,c) return not c:IsType(TYPE_SYNCHRO) end)
	end
end

-----------------------------------
-- ② 효과
-----------------------------------
function s.tuner_filter(c)
	return c:IsType(TYPE_TUNER) and c:IsMonster() and c:IsAbleToRemove()
end
function s.nontuner_filter(c,sum)
	return not c:IsType(TYPE_TUNER) and c:IsMonster() and c:IsAbleToRemove() and c:GetLevel()>0 and (sum+c:GetLevel())<=8
end
function s.ex_target_filter(c,lv,e,tp)
	return c:IsSetCard(0x760) and c:IsType(TYPE_SYNCHRO) and c:IsLevel(lv)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tuner_filter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_EXTRA,0,1,nil,0x760)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.exop(e,tp,eg,ep,ev,re,r,rp)
	-- 튜너 1장 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local tuner=Duel.SelectMatchingCard(tp,s.tuner_filter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #tuner==0 then return end
	local g_remove=Group.CreateGroup()
	g_remove:Merge(tuner)
	local sum=tuner:GetFirst():GetLevel()

	-- 추가로 튜너 이외를 선택 (레벨 합계 ≤8)
	while true do
		local cand=Duel.GetMatchingGroup(function(c) return s.nontuner_filter(c,sum) end,tp,LOCATION_GRAVE,0,nil)
		if #cand==0 or sum>=8 then break end
		if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then break end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sel=Duel.SelectMatchingCard(tp,function(c) return s.nontuner_filter(c,sum) end,tp,LOCATION_GRAVE,0,1,1,nil)
		if #sel==0 then break end
		sum=sum+sel:GetFirst():GetLevel()
		g_remove:Merge(sel)
	end

	if sum<=0 or sum>8 then return end
	if not Duel.IsExistingMatchingCard(function(c) return s.ex_target_filter(c,sum,e,tp) end,tp,LOCATION_EXTRA,0,1,nil) then return end

	-- 제외 실행
	if Duel.Remove(g_remove,POS_FACEUP,REASON_EFFECT+REASON_COST)==0 then return end

	-- 특수 소환
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,function(c) return s.ex_target_filter(c,sum,e,tp) end,tp,LOCATION_EXTRA,0,1,1,nil):GetFirst()
	if sc and Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end
