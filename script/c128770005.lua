local s, id = GetID()
function s.initial_effect(c)
	-- Special summon self from hand
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.sspconswan)
	c:RegisterEffect(e1)

	-- Change Level
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + 1) -- Use a different ID for this effect
	e2:SetTarget(s.stargetdre)
	e2:SetOperation(s.sactivatedre)
	c:RegisterEffect(e2)

	-- Disable effect
	local e3 = Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DISABLE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1, id + 2) -- Use a different ID for this effect
	e3:SetTarget(s.sdistgdrm)
	e3:SetOperation(s.sdisopdrm)
	c:RegisterEffect(e3)
end

-- Special summon condition
function s.sspfilterswan(c)
	return c:IsFaceup() and c:IsSetCard(0x30d)
end

function s.sspconswan(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.sspfilterswan, tp, LOCATION_MZONE, 0, 1, nil)
end

-- Change Level target and operation
function s.sfilter1dr(c)
	return c:IsFaceup() and c:HasLevel()
end

function s.stargetdre(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.sfilter1dr(chkc) end
	if chk == 0 then return Duel.IsExistingTarget(s.sfilter1dr, tp, LOCATION_MZONE, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.sfilter1dr, tp, LOCATION_MZONE, 0, 1, 1, nil)
end

function s.sactivatedre(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local lv = tc:GetLevel()
		local g = Duel.GetMatchingGroup(s.sfilter1dr, tp, LOCATION_MZONE, 0, tc)
		for lc in aux.Next(g) do
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL_FINAL)
			e1:SetValue(lv)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			lc:RegisterEffect(e1)
		end
	end
end

-- Disable effect target and operation
function s.sfilterdrm(c, e)
	return c:IsFaceup() and c:IsType(TYPE_EFFECT) and (not e or c:IsCanBeEffectTarget(e)) and not c:IsDisabled()
end

function s.sdistgdrm(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) and chkc:IsFaceup() end
	if chk == 0 then return Duel.IsExistingTarget(s.sfilterdrm, tp, 0, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_NEGATE)
	local g = Duel.SelectTarget(tp, s.sfilterdrm, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.sdisopdrm(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(e1)
		local e2 = Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(e2)
	end
end
