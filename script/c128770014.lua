local s, id = GetID()
function s.initial_effect(c)
	-- Enable Counter Permit and Counter Use
	c:EnableCounterPermit(0x1657)  -- Define "악장 카운터" with ID 0x1

	-- Fusion Summon
	c:EnableReviveLimit()
	Fusion.AddProcMix(c, true, true, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), s.synfilter)

	-- Add Act Counter on each Standby Phase
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE + PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetOperation(s.addcounter)
	c:RegisterEffect(e1)

	-- Effect: Reduce opponent's monsters' attack based on Act Counters
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0, LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Effect 2: Restrict attacks and negate effects
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0, LOCATION_MZONE)
	e3:SetCondition(s.restrictcond)
	c:RegisterEffect(e3)

	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_TRIGGER)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0, LOCATION_MZONE)
	e4:SetCondition(s.restrictcond)
	c:RegisterEffect(e4)

	-- Effect 3: Banish all opponent's cards
	local e5 = Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id, 0))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCondition(s.banishcond)
	e5:SetTarget(s.banishtg)
	e5:SetOperation(s.banishop)
	c:RegisterEffect(e5)
end

-- Filter for "M.A" Synchro Monster
function s.synfilter(c)
	return c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0x30d)
end

-- Add Act Counter
function s.addcounter(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:GetCounter(0x1657) < 5 then
		c:AddCounter(0x1657, 1)
	end
end

-- Attack Reduction Value
function s.atkval(e, c)
	return -e:GetHandler():GetCounter(0x1657) * 1000
end

-- Condition for Restriction Effects
function s.restrictcond(e)
	return e:GetHandler():GetCounter(0x1657) >= 3
end

-- Condition for Banish Effect
function s.banishcond(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():GetCounter(0x1) == 5
end

-- Target for Banish Effect
function s.banishtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD + LOCATION_GRAVE, 1, nil) end
	local g = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD + LOCATION_GRAVE, nil)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, #g, 0, 0)
end

-- Operation for Banish Effect
function s.banishop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD + LOCATION_GRAVE, nil)
	if #g > 0 then
		Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
	end
end
