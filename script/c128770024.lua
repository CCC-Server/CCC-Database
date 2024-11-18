local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x30d),1,1,Synchro.NonTunerEx(Card.IsSetCard,0x30d),1,99)
	c:EnableReviveLimit()

	-- Effect 1: Destroy all Spell/Trap cards on opponent's field
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- Effect 2: Banish 1 Spell/Trap card on opponent's field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetHintTiming(0, TIMINGS_CHECK_MONSTER+TIMING_SSET)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

-- Effect 1: Condition to activate if no other cards are on your field
function s.descon(e)
	return e:GetHandler():IsLocation(LOCATION_MZONE) and Duel.GetFieldGroupCount(e:GetHandlerPlayer(), LOCATION_ONFIELD, 0)==1
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_SZONE, 1, nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_SZONE, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local g=Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_SZONE, nil)
	if #g>0 then
		Duel.Destroy(g, REASON_EFFECT)
	end
end

-- Effect 2: Target and banish 1 Spell/Trap card on opponent's field
function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType, tp, 0, LOCATION_SZONE, 1, nil, TYPE_SPELL+TYPE_TRAP) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp, Card.IsType, tp, 0, LOCATION_SZONE, 1, 1, nil, TYPE_SPELL+TYPE_TRAP)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 1, 0, 0)
end
function s.rmop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc, POS_FACEUP, REASON_EFFECT)
	end
end
