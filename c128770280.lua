--스펠크래프트 아르카나 마기스 (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건: "스펠크래프트" 몬스터 2장 이상
	Link.AddProcedure(c,s.matfilter,2,99)
	c:EnableReviveLimit()

	--① 공격력 상승: 마력 카운터 수 × 800
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	--② (프리체인) 턴 종료시까지 아군 "스펠크래프트" 몬스터 전투 파괴 내성
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,{id,1})
	e2:SetOperation(s.indop)
	c:RegisterEffect(e2)
end

--링크 소재: "스펠크래프트" 몬스터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x761,lc,sumtype,tp)
end

--① 공격력 상승 계산: 필드 전체의 마력 카운터 수 × 800
function s.atkval(e,c)
	local ct=Duel.GetCounter(c:GetControler(),LOCATION_ONFIELD,LOCATION_ONFIELD,0x1)
	return ct*800
end

--② 전투 파괴 내성 부여
function s.indop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x761))
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- 시각적 표시용 메시지
	Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,2))
end
