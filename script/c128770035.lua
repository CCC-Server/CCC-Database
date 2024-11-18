local s, id = GetID()
function s.initial_effect(c)
	-- Link Summon
	Link.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), 2)
	c:EnableReviveLimit()

	-- Effect 1: Special summon "M.A" monster from the GY
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptarget)
	e1:SetOperation(s.spoperation)
	c:RegisterEffect(e1)

	-- Effect 2: Destroy Spell/Trap when a linked Xyz monster activates its effect
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.descon)
	e2:SetCountLimit(1, {id, 1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- Effect 1: Cost to banish 1 card from the hand
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, LOCATION_HAND, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, Card.IsAbleToRemove, tp, LOCATION_HAND, 0, 1, 1, nil)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
end

-- Effect 1: Target to special summon "M.A" monster from the GY
function s.sptarget(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and chkc:IsSetCard(0x30d) and chkc:IsMonster() end
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingTarget(aux.NecroValleyFilter(Card.IsMonster, Card.IsSetCard), tp, LOCATION_GRAVE, 0, 1, nil, 0x30d) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectTarget(tp, aux.NecroValleyFilter(Card.IsMonster, Card.IsSetCard), tp, LOCATION_GRAVE, 0, 1, 1, nil, 0x30d)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

-- Effect 1: Special summon the targeted "M.A" monster
function s.spoperation(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- Effect 2: Check if the Xyz monster in the linked zone activates its effect
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsStatus(STATUS_BATTLE_DESTROYED) then return false end

	local rc = re:GetHandler()
	return rc:IsType(TYPE_XYZ) and rc:IsLocation(LOCATION_MZONE) and c:GetLinkedGroup():IsContains(rc)
end

function s.desfilter(c)
	return c:IsType(TYPE_SPELL + TYPE_TRAP)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1 - tp) and s.desfilter(chkc) end
	if chk == 0 then return Duel.IsExistingTarget(s.desfilter, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, s.desfilter, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
