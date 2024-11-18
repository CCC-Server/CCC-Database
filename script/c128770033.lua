local s, id = GetID()
function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c, nil, 10, 3)
	c:EnableReviveLimit()
	
	-- Effect 1: Destroy opponent's monsters with equal or less ATK
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destarget)
	e1:SetOperation(s.desoperation)
	c:RegisterEffect(e1)

	-- Effect 2: Special summon up to 3 banished "M.A" monsters
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptarget)
	e2:SetOperation(s.spoperation)
	c:RegisterEffect(e2)
end

-- Effect 1: Cost to remove 1 Xyz Material
function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

-- Effect 1: Target to destroy opponent's monsters
function s.destarget(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsFaceup() and chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 0, 1 - tp, LOCATION_MZONE)
end

-- Effect 1: Operation to destroy opponent's monsters
function s.desoperation(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		local atk = tc:GetAttack()
		-- Destroy all opponent's monsters on the field with ATK less than or equal to the selected monster's ATK
		local g = Duel.GetMatchingGroup(function(c)
			return c:IsFaceup() and c:GetAttack() <= atk and c:IsControler(1 - tp)
		end, tp, 0, LOCATION_MZONE, nil)
		if #g > 0 then
			Duel.Destroy(g, REASON_EFFECT)
		end
	end
end

-- Effect 2: Condition to special summon
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end

-- Effect 2: Target to special summon up to 3 banished "M.A" monsters
function s.sptarget(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and
			Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_REMOVED, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_REMOVED)
end

-- Effect 2: Operation to special summon
function s.spfilter(c, e, tp)
	return c:IsSetCard(0x30d) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.spoperation(e, tp, eg, ep, ev, re, r, rp)
	local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
	local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_REMOVED, 0, nil, e, tp)
	if ft > 0 and #g > 0 then
		local lv = 0
		local sg = Group.CreateGroup()
		repeat
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
			local tc = g:Select(tp, 1, 1, nil):GetFirst()
			g:RemoveCard(tc)
			sg:AddCard(tc)
			lv = lv + tc:GetLevel()
			ft = ft - 1
		until ft <= 0 or #g == 0 or lv >= 10
		Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
	end
end

