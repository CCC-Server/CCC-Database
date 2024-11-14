--주술회전 푸가
function c128380011.initial_effect(c)
end
--scripted by Naim
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetHintTiming(TIMING_ATTACK,TIMINGS_CHECK_MONSTER_E|TIMING_ATTACK)
	c:RegisterEffect(e0)
	
	-- Destroy face-up cards your opponent controls up to the number of "Raizeol" Ritual monsters you control
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetHintTiming(0, TIMING_MAIN_END)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- Must attack highest ATK "Raizeol" monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_MUST_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(0, LOCATION_MZONE)
	e2:SetCondition(s.atcon)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_MUST_ATTACK_MONSTER)
	e3:SetValue(s.atlimit)
	c:RegisterEffect(e3)
end
s.listed_series={0xc41}

-- Filter for counting "Raizeol" Ritual monsters
function s.desconfilter(c)
	return c:IsSetCard(0xc41) and c:IsType(TYPE_RITUAL) and c:IsFaceup()
end

-- Targeting for destruction
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1 - tp) and chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsFaceup() end
	local ct = Duel.GetMatchingGroupCount(s.desconfilter, tp, LOCATION_MZONE, 0, nil)
	if chk == 0 then return ct > 0 and Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local dg = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, ct, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, dg, #dg, 0, 0)
end

-- Operation for destruction
function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local dg = Duel.GetTargetCards(e)
	if #dg > 0 then
		Duel.Destroy(dg, REASON_EFFECT)
	end
end

-- Attack condition
function s.atcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard, 0xc41), e:GetHandlerPlayer(), LOCATION_MZONE, 0, 1, nil)
end

-- Attack limit
function s.atlimit(e, c)
	local g = Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard, 0xc41), e:GetHandlerPlayer(), LOCATION_MZONE, 0, nil)
	local tg = g:GetMaxGroup(Card.GetAttack)
	return tg and tg:IsContains(c)
end
