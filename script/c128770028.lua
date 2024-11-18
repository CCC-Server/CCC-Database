local s, id = GetID()
function s.initial_effect(c)
	--Xyz Summon
	Xyz.AddProcedure(c,nil,7,2)
	c:EnableReviveLimit()
	-- Effect 1: Opponent cannot activate effects during this card's attack
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	-- Effect 2: Increase attack during battle with Special Summoned monster
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e2:SetCountLimit(1, id)
	e2:SetCondition(s.atkcon)
	e2:SetCost(s.atkcost)
	e2:SetOperation(s.atkop2)
	c:RegisterEffect(e2)
end

-- Effect 1: Opponent cannot activate effects during this card's attack
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0, 1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE + PHASE_DAMAGE)
	Duel.RegisterEffect(e1, tp)
end

function s.aclimit(e, re, tp)
	return re:IsActiveType(TYPE_MONSTER + TYPE_SPELL + TYPE_TRAP)
end

-- Effect 2: Increase attack during battle with Special Summoned monster
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local bc = c:GetBattleTarget()
	return bc and bc:IsControler(1 - tp) and bc:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

function s.atkop2(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local bc = c:GetBattleTarget()
	if bc and c:IsRelateToBattle() and c:IsFaceup() then
		local atk = bc:GetAttack()
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_DAMAGE_CAL)
		c:RegisterEffect(e1)
	end
end
