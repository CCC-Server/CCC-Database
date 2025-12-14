local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 절차
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,
		aux.FilterSummonCode,1,99,s.matfilter)
	c:EnableReviveLimit()

	------------------------------------------
	--① 추가 공격 횟수
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e1:SetValue(s.extraval)
	c:RegisterEffect(e1)

	------------------------------------------
	--② 몬스터 파괴 시 ATK 상승
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCondition(aux.bdocon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	------------------------------------------
	--③ 특정 싱크로 소재로 소환 시 전투 중 제약
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.actcon)
	e3:SetOperation(s.actop)
	c:RegisterEffect(e3)
end
s.listed_series={0x760}

-------------------------------------------------
--싱크로 소재 조건
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x760,lc,sumtype,tp) and not c:IsType(TYPE_TUNER,lc,sumtype,tp)
end

-------------------------------------------------
--① 추가 공격 횟수 계산
function s.extraval(e,c)
	local tp=c:GetControler()
	local ct=Duel.GetMatchingGroupCount(aux.FilterFaceupFunction(Card.IsSetCard,0x760),tp,LOCATION_MZONE,0,nil)
	return math.max(ct-1,0) -- 자신 포함이므로 -1 처리
end

-------------------------------------------------
--② 공격력 +500
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToBattle() and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-------------------------------------------------
--③ "스파클 아르카디아" 싱크로를 소재로 싱크로 소환된 경우
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	if a~=c then return false end
	-- 이 카드가 스파클 아르카디아 싱크로를 소재로 싱크로 소환된 경우만 발동
	local mg=c:GetMaterial()
	if not mg or not mg:IsExists(Card.IsType,1,nil,TYPE_SYNCHRO) then return false end
	if not mg:IsExists(Card.IsSetCard,1,nil,0x760) then return false end
	return true
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetAttackTarget()
	if not tc then return end
	-- 상대는 데미지 스텝 종료시까지 마/함 발동 불가
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_DAMAGE)
	Duel.RegisterEffect(e1,tp)
	-- 전투 중인 상대 몬스터의 효과 무효
	if tc:IsFaceup() and tc:IsRelateToBattle() then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
		tc:RegisterEffect(e2)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_EFFECT)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
		tc:RegisterEffect(e3)
	end
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end
