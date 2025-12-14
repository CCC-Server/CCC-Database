--드래곤 듀얼 퓨전 마스터 (예시 이름)
local s,id=GetID()
-- 안전 상수 보정
EFFECT_DUAL_STATUS = EFFECT_DUAL_STATUS or 778

function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)
	
	--① 필드의 듀얼 몬스터는 1번 더 일반 소환된 상태로 취급
	--duel status
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsType,TYPE_GEMINI))
	e1:SetCode(EFFECT_GEMINI_STATUS)
	c:RegisterEffect(e1)

	--② 전투 시 데미지 계산하지 않고 상대 몬스터 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e2:SetCondition(s.descon)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--③ 1턴에 1번, 자신/상대 턴에 선택 발동
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetOperation(s.op)
	c:RegisterEffect(e3)
end


--융합 소재: 드래곤족 듀얼 몬스터 × 2
function s.matfilter1(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_GEMINI,fc,sumtype,tp)
end
function s.matfilter2(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_GEMINI,fc,sumtype,tp)
end

--② 전투 파괴 효과
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(1-tp) and bc:IsRelateToBattle()
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		Duel.Destroy(bc,REASON_EFFECT)
		Duel.SkipPhase(1-tp,PHASE_DAMAGE_CAL,true)
		Duel.SkipPhase(1-tp,PHASE_DAMAGE,true)
	end
end

--③ 선택 발동
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	if op==0 then
		--①: 원래 공격력 ≠ 현재 공격력인 공격표시 몬스터 전부 파괴
		local g=Duel.GetMatchingGroup(s.atkfilter,tp,0,LOCATION_MZONE,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	else
		--②: 상대 패/필드의 모든 몬스터의 레벨 2배로 (턴 종료시까지)
		local g1=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_HAND+LOCATION_MZONE,nil)
		for tc in g1:Iter() do
			local lv=tc:GetLevel()
			if lv>0 then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_LEVEL)
				e1:SetValue(lv)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
			end
		end
	end
end
function s.atkfilter(c)
	return c:IsFaceup() and c:IsAttackPos() and c:GetAttack()~=c:GetBaseAttack()
end
