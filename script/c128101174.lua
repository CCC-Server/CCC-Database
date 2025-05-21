--어보미네이션 디바인 블레이저
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 조건: 기계족 튜너 + 튜너 이외 몬스터 1장 이상
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_MACHINE),1,1,aux.TRUE,1,99)

	-- 어보미네이션 튜너 대체 처리 (싱크로 소환 시)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_CHANGE_TYPE)
	e0:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetTargetRange(LOCATION_MZONE,0)
	e0:SetTarget(function(e,c)
		return c:IsSetCard(0xc42) and not c:IsType(TYPE_TUNER)
	end)
	e0:SetValue(TYPE_MONSTER+TYPE_TUNER+TYPE_EFFECT)
	c:RegisterEffect(e0)

	-- ①: 싱크로 소환 성공 시 필드 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.rmcon)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- ②: 싱크로 소환 턴에 따라 지속 효과 부여
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.labelcon)
	e2:SetOperation(s.labelop)
	c:RegisterEffect(e2)
end

-- 싱크로 소환 시 조건
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

-- 싱크로 소환 성공 시 턴 체크하여 라벨 부여
function s.labelcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.labelop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local turnPlayer = Duel.GetTurnPlayer()
	if tp == turnPlayer then
		-- 자신의 턴에 소환된 경우: 공격시 상대는 효과 발동 불가
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e1:SetTargetRange(0,LOCATION_ONFIELD)
		e1:SetCondition(s.actcon)
		e1:SetValue(s.actlimit)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	else
		-- 상대 턴에 소환된 경우: 내 몬스터는 효과로 파괴되지 않음
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e2:SetRange(LOCATION_MZONE)
		e2:SetTargetRange(LOCATION_MZONE,0)
		e2:SetTarget(aux.TargetBoolFunction(Card.IsControler,tp))
		e2:SetValue(1)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end

-- 자신의 턴 공격 중, 데미지 스텝 중에는 상대 효과 발동 불가
function s.actcon(e)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetAttacker():IsControler(tp) and ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end
function s.actlimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
end
