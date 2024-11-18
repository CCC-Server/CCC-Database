local s, id = GetID()
function s.initial_effect(c)
-- Synchro Summon
Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), 1, 1, Synchro.NonTuner(Card.IsSetCard, 0x30d), 1, 99)
c:EnableReviveLimit()

-- Place Frost Shard Counter (Once per turn, Quick Effect)
local e1 = Effect.CreateEffect(c)
e1:SetDescription(aux.Stringid(id, 0))
e1:SetCategory(CATEGORY_COUNTER)
e1:SetType(EFFECT_TYPE_QUICK_O)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
e1:SetRange(LOCATION_MZONE)
e1:SetCountLimit(1)
e1:SetTarget(s.counter_target)
e1:SetOperation(s.counter_operation)
e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
c:RegisterEffect(e1)

-- Negate effects of monsters with Frost Shard Counter
local e2 = Effect.CreateEffect(c)
e2:SetType(EFFECT_TYPE_FIELD)
e2:SetCode(EFFECT_DISABLE)
e2:SetRange(LOCATION_MZONE)
e2:SetTargetRange(0, LOCATION_MZONE)
e2:SetTarget(s.disable_target)
c:RegisterEffect(e2)

-- Destroy Special Summoned monsters when a monster with Frost Shard Counter leaves the field
--register when a card leaves the field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_LEAVE_FIELD_P)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)
--add to hand
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,128770026)
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	e4:SetLabelObject(e3)
	c:RegisterEffect(e4)
end

-- Function to target a monster to place a counter
function s.counter_target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
if chkc then return chkc:IsOnField() and chkc:IsFaceup() and chkc:IsControler(1 - tp) end
if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
Duel.SetOperationInfo(0, CATEGORY_COUNTER, g, 1, 0, 0x1017)
end

-- Function to place the Frost Shard Counter
function s.counter_operation(e, tp, eg, ep, ev, re, r, rp)
local tc = Duel.GetFirstTarget()
if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
tc:AddCounter(0x1017, 1)
end
end

-- Function to disable effects of monsters with Frost Shard Counter
function s.disable_target(e, c)
return c:GetCounter(0x1017) > 0
end

-- Condition to trigger destruction effect
function s.destroy_condition(e, tp, eg, ep, ev, re, r, rp)
return eg:IsExists(s.counter_filter, 1, nil)
end

-- Filter to check if the monster had a Frost Shard Counter
function s.counter_filter(c)
return c:IsPreviousLocation(LOCATION_MZONE) and c:GetCounter(0x1017) > 0
end
function s.lvfdfilter(c)
	return c:IsLocation(LOCATION_MZONE) and c:GetCounter(0x1017)>0
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(s.lvfdfilter,1,nil) then
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetLabelObject():GetLabel()==1
end

function s.desfilter(c)
	return c:IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil)
	Duel.Destroy(g,REASON_EFFECT)
end
