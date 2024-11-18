local s,id=GetID()
function s.initial_effect(c)
	-- Cannot be Normal Summoned/Set
	c:EnableReviveLimit()
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.fuslimit)
	c:RegisterEffect(e0)

	-- Effect 1: Cannot be destroyed by battle or opponent's effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(aux.indoval)
	c:RegisterEffect(e2)

	-- Effect 2: Special Summon "M.A-아무 것도 없는(최종변이)"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg23)
	e3:SetOperation(s.spop23)
	c:RegisterEffect(e3)
end

-- Special Summon cost
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(), REASON_COST)
end

-- Special Summon target
function s.sptg23(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp)>0 and Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsCode, 128770018), tp, LOCATION_EXTRA, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

-- Special Summon operation
function s.spop23(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp, aux.FilterBoolFunction(Card.IsCode, 128770018), tp, LOCATION_EXTRA, 0, 1, 1, nil):GetFirst()
	if sc and Duel.SpecialSummon(sc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP)~=0 then
		sc:CompleteProcedure()
	end
end
