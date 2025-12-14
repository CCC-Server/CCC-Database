local s,id=GetID()
function s.initial_effect(c)
		-- Synchro Summon procedure
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsAttribute,ATTRIBUTE_FIRE),1,99)

	-- 효과①: 관통 / 연속공격 / 전투 시 ATK 상승
	-- 적용용 continuous effect (묘지의 라바르 수에 따라 얻는 효과)

	-- ●2장 이상: 관통
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PIERCE)
	e1:SetCondition(s.piercecon)
	c:RegisterEffect(e1)

	-- ●3장 이상: 몬스터 파괴 시 추가 공격
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCountLimit(1)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- ●4장 이상: 전투 시 ATK 상승
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e3:SetCondition(s.atkupcon)
	e3:SetOperation(s.atkupop)
	c:RegisterEffect(e3)
end

-- 🔹소재 조건: 튜너 + 튜너 이외의 화염 속성 몬스터
function s.matfilter(c,sc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and not c:IsType(TYPE_TUNER)
end

-- 🔹조건: 내 묘지의 라바르 몬스터 수
function s.laval_count(tp)
	return Duel.GetMatchingGroupCount(s.lavalfilter,tp,LOCATION_GRAVE,0,nil)
end
function s.lavalfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster()
end

-- 🔹2장 이상 → 관통
function s.piercecon(e)
	local tp=e:GetHandlerPlayer()
	return s.laval_count(tp)>=2
end

-- 🔹3장 이상 → 몬스터 파괴 시 추가 공격
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return s.laval_count(tp)>=3 and e:GetHandler():IsRelateToBattle()
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end

-- 🔹4장 이상 → 특수 소환 몬스터와 전투 시 ATK 증가
function s.atkupcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsSummonType(SUMMON_TYPE_SPECIAL) and s.laval_count(tp)>=4
end
function s.atkupop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if c:IsFaceup() and bc and bc:IsFaceup() then
		local atk=bc:GetAttack()
		if atk<=0 then return end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE_CAL)
		c:RegisterEffect(e1)
	end
end
