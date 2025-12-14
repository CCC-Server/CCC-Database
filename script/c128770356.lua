local s,id=GetID()
function s.initial_effect(c)
--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x767),1,99)
	c:EnableReviveLimit()
	-- ① 공격력 / 수비력 설정
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e2)

	-- ② 전체 몬스터에게 공격 가능
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_ATTACK_ALL)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	-- ③ 타겟 내성 (10회 이상 소환 시)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.untgcon)
	e4:SetValue(aux.tgoval)
	c:RegisterEffect(e4)

	-- 소환 횟수 추적용 글로벌 효과
	if not s.global_check then
		s.global_check=true
		s.summon_count={}
		local ge1=Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SUMMON_SUCCESS)
		ge1:SetOperation(s.countop)
		Duel.RegisterEffect(ge1,0)
		local ge2=ge1:Clone()
		ge2:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(ge2,0)

		local ge3=Effect.GlobalEffect()
		ge3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge3:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge3:SetOperation(function()
			s.summon_count[0]=0
			s.summon_count[1]=0
		end)
		Duel.RegisterEffect(ge3,0)
	end
end

-- 싱크로 재료: "요정향" 비튜너
function s.matfilter(c)
	return c:IsSetCard(0x767) and not c:IsType(TYPE_TUNER)
end

-- ① 공격력 / 수비력 = 이번 턴 소환 횟수 × 500
function s.atkval(e,c)
	local tp=c:GetControler()
	return (s.summon_count[tp] or 0)*500
end

-- 소환 횟수 추적
function s.countop(e,tp,eg,ep,ev,re,r,rp)
	for p=0,1 do
		if not s.summon_count[p] then s.summon_count[p]=0 end
	end
	for tc in eg:Iter() do
		local p=tc:GetSummonPlayer()
		s.summon_count[p]=s.summon_count[p]+1
	end
end

-- ③ 효과: 소환 10회 이상일 때 대상 불가
function s.untgcon(e)
	local tp=e:GetHandlerPlayer()
	return (s.summon_count[tp] or 0)>=10
end
