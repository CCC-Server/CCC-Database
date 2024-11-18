local s,id=GetID()
function s.initial_effect(c)
	--fusion material
	Fusion.AddProcMixN(c, true, true, aux.FilterBoolFunctionEx(Card.IsSetCard, 0x30d), 2)
	c:EnableReviveLimit()

	--damage effect
	--atkup
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.atkcost)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	--battle destroy effect
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCondition(s.eqcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--continuous effect
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1, 1)
	e3:SetCondition(s.descon)
	e3:SetValue(s.aclimit)
	c:RegisterEffect(e3)

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_DISABLE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_ONFIELD, LOCATION_ONFIELD)
	e4:SetCondition(s.descon)
	e4:SetTarget(s.disable)
	c:RegisterEffect(e4)
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,nil,e:GetHandler()) end
	local g=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,nil,e:GetHandler())
	Duel.Release(g,REASON_COST)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(600)
		c:RegisterEffect(e1)
	end
end
function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = c:GetBattleTarget()
	return c:IsRelateToBattle() and c:IsFaceup() and tc and tc:IsLocation(LOCATION_GRAVE) and tc:IsMonster() and tc:IsReason(REASON_BATTLE)
end

function s.sptg(e, tp, eg, ep, ev, re, r, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsPlayerCanSpecialSummonMonster(tp, 128770043, 0, TYPES_TOKEN, 1300, 1050, 4, RACE_FIEND, ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0, CATEGORY_TOKEN, nil, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsPlayerCanSpecialSummonMonster(tp, 128770043, 0, TYPES_TOKEN, 1300, 1050, 4, RACE_FIEND, ATTRIBUTE_DARK) then
		local token = Duel.CreateToken(tp, 128770043)
		Duel.SpecialSummon(token, 0, tp, tp, false, false, POS_FACEUP_ATTACK)
	end
end

function s.descon(e)
	return Duel.GetMatchingGroupCount(Card.IsCode, e:GetHandlerPlayer(), LOCATION_MZONE, 0, nil, 128770043) >= 3
end

function s.aclimit(e, re, tp)
	return re:GetHandler():IsOnField() and e:GetHandler() ~= re:GetHandler()
end

function s.disable(e, c)
	return c ~= e:GetHandler() and (not c:IsType(TYPE_MONSTER) or c:IsType(TYPE_EFFECT))
end

