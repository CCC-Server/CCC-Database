local s, id = GetID()
function s.initial_effect(c)
	-- ① Level up during your Standby Phase
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE + PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetOperation(s.lvop)
	c:RegisterEffect(e1)
	-- ② ATK/DEF = Level x 200
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.adval)
	c:RegisterEffect(e2)
	local e2b = e2:Clone()
	e2b:SetCode(EFFECT_SET_DEFENSE)
	c:RegisterEffect(e2b)
	-- ③ Special Summon from hand if you control a Fortune Lady monster
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1, id)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	-- ④ Trigger when this leaves the field by a Fortune Lady effect
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

-- ① Level up operation
function s.lvop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsFaceup() and c:GetLevel() < 12 then
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_STANDBY)
		c:RegisterEffect(e1)
	end
end

-- ② ATK/DEF value calculation
function s.adval(e, c)
	return c:GetLevel() * 200
end

-- Filter for Fortune Lady monsters
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x31) and c:IsType(TYPE_MONSTER)
end

-- ③ Special Summon from hand condition
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

-- ③ Target and operation
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ④ Condition: left by Fortune Lady effect
-- ④ Trigger when this leaves the field by a Fortune Lady effect
function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	return re and re:IsActivated() and re:GetHandler():IsSetCard(0x31)
end

function s.spfilter2(c, e, tp)
	return c:IsSetCard(0x31) and c:IsType(TYPE_MONSTER)
		and not c:IsCode(128770081) -- "포츈 레이디 타이미"의 카드 ID로 대체
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_REMOVED)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
	local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
	if ft <= 0 then return end
	local g = Duel.GetMatchingGroup(s.spfilter2, tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_REMOVED, 0, nil, e, tp)
	if #g == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local sg = g:Select(tp, 1, math.min(2, ft), nil)
	Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
end
