local s, id = GetID()
function s.initial_effect(c)
	-- Fusion Summon procedure
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c, true, true, aux.FilterBoolFunctionEx(Card.IsSetCard, 0x30d), 3)

	-- Effect 1: Attack restriction (opponent cannot activate effects during the damage step)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0, 1)
	e1:SetValue(s.aclimit)
	e1:SetCondition(s.atkcon)
	c:RegisterEffect(e1)

	-- Effect 2: Copy effect from GY
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCost(s.copycost)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)

	-- Effect 3: Special Summon "M.A-아무 것도 없는 고치"
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLED)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- Effect 1: Activation restriction during attack
function s.aclimit(e, re, tp)
	return re:IsActiveType(TYPE_MONSTER + TYPE_SPELL + TYPE_TRAP) and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end

function s.atkcon(e)
	local c = e:GetHandler()
	return c:IsAttackPos() and Duel.GetCurrentPhase() == PHASE_DAMAGE and not Duel.IsDamageCalculated()
end

-- Effect 2: Copy effect from GY
function s.copycost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(
			function(c) return c:IsSetCard(0x30d) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost() end,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(
		tp,
		function(c) return c:IsSetCard(0x30d) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost() end,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
	e:SetLabelObject(g:GetFirst())
end

function s.copyop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = e:GetLabelObject()
	if tc and c:IsRelateToEffect(e) then
		local code = tc:GetOriginalCodeRule()
		c:CopyEffect(code, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 1)
	end
end

-- Effect 3: Special Summon "M.A-아무 것도 없는 고치" at the end of the Battle Phase
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	-- Check if this card has battled during this Battle Phase
	return e:GetHandler():GetBattledGroupCount() > 0
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(), REASON_COST)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCountFromEx(tp) > 0
			and Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_EXTRA, 0, 1, nil, 128770017)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCountFromEx(tp) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local sc = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_EXTRA, 0, 1, 1, nil, 128770017):GetFirst()
	if sc and Duel.SpecialSummon(sc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP) ~= 0 then
		sc:CompleteProcedure()
	end
end