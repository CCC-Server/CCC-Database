local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon procedure
	Fusion.AddProcMixN(c, true, true, aux.FilterBoolFunctionEx(Card.IsSetCard, 0x30d), 2)
	c:EnableReviveLimit()

	-- Cannot be destroyed by battle
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Fusion substitute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_FUSION_SUBSTITUTE)
	e2:SetCondition(s.subcon)
	c:RegisterEffect(e2)

	-- Add slime counter and disable effects
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.counter_condition)
	e3:SetOperation(s.counter_operation)
	c:RegisterEffect(e3)
end

function s.subcon(e)
	return e:GetHandler():IsLocation(LOCATION_ONFIELD+LOCATION_GRAVE)
end

function s.counter_condition(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local at=Duel.GetAttackTarget()
	return Duel.GetAttacker()==c and at and at:IsRelateToBattle() and at:GetCounter(0x1024)==0
end

function s.counter_operation(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local at=Duel.GetAttackTarget()
	if at and at:IsRelateToBattle() then
		-- Add slime counter
		at:AddCounter(0x1024, 1)
		-- Prevent the monster from attacking
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		at:RegisterEffect(e1)
		-- Disable the monster's effects
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		at:RegisterEffect(e2)
	end
end