local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon
	Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), 1, 1, Synchro.NonTuner(nil), 1, 99)
	c:EnableReviveLimit()

	-- Effect 1: Add 1 banished "M.A" monster to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effect 2: Gain control of a monster and redirect attack
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.ctrlcon)
	e2:SetTarget(s.ctrltg)
	e2:SetOperation(s.ctrop)
	c:RegisterEffect(e2)
end

-- Effect 1: Condition to trigger when Synchro Summoned
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.thfilter(c)
	return c:IsSetCard(0x30d) and c:IsAbleToHand() and c:IsFaceup() and c:IsLocation(LOCATION_REMOVED)
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter, tp, LOCATION_REMOVED, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp, s.thfilter, tp, LOCATION_REMOVED, 0, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc, nil, REASON_EFFECT)
	end
end

-- Effect 2: Gain control of a monster and redirect attack
function s.ctrlcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetAttacker():IsControler(1-tp)
end
function s.ctrltg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE, tp, 0, LOCATION_MZONE, 1, Duel.GetAttacker()) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp, aux.TRUE, tp, 0, LOCATION_MZONE, 1, 1, Duel.GetAttacker())
	Duel.SetOperationInfo(0, CATEGORY_CONTROL, g, 1, 0, 0)
end
function s.ctrop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.GetControl(tc, tp, PHASE_BATTLE, 1) then
		Duel.ChangeAttackTarget(tc)
	end
end
