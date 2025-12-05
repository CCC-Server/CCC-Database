--오버 리밋 • 블레이징 머신
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_MACHINE),1,1,Synchro.NonTuner(Card.IsRace,RACE_MACHINE),1,99)
	c:EnableReviveLimit()

	--①: 공격력 변동 (자신 필드 +500~1000)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetValue(s.atkval_own)
	c:RegisterEffect(e1)

	--①: 공격력 변동 (상대 필드 -1000)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetValue(-1000)
	c:RegisterEffect(e2)

	--②: 몬스터 효과 무효 및 공뻥
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id) -- 1턴에 1번
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	--③: 효과 파괴 내성
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetCondition(s.indcon)
	e4:SetValue(1)
	c:RegisterEffect(e4)
end

s.listed_series={0xc48}
s.listed_names={23171610} -- 리미터 해제

-- ① 효과: 자신 필드 몬스터 공격력 증가 수치 계산
function s.atkval_own(e,c)
	local tp=e:GetHandlerPlayer()
	-- 묘지에 "리미터 해제"가 있으면 500 + 500 = 1000 증가, 없으면 500 증가
	if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,23171610),tp,LOCATION_GRAVE,0,1,nil) then
		return 1000
	else
		return 500
	end
end

-- ② 효과 조건: 발동한 몬스터의 공격력이 이 카드의 공격력 이하일 때
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER) 
		and rc:GetAttack()<=c:GetAttack() 
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,nil,0,tp,500)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		-- 자신 필드의 모든 몬스터 공격력 500 증가 (영구 지속)
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(500)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end

-- ③ 효과 조건: 현재 공격력이 원래 공격력의 2배 이상일 때
function s.indcon(e)
	local c=e:GetHandler()
	return c:GetAttack() >= c:GetBaseAttack()*2
end