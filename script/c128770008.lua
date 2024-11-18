local s, id = GetID()
function s.initial_effect(c)
	-- 효과 1: 소환 성공 시 효과
	local e1 = Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetType(EFFECT_TYPE_TRIGGER_O + EFFECT_TYPE_SINGLE)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.tgma)
	e1:SetOperation(s.opms)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- 효과 2: 융합 소환 및 특수 소환
	local e3 = Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.target5)
	e3:SetOperation(s.activate5)
	c:RegisterEffect(e3)
end

function s.filterma(c)
	return c:IsSetCard(0x30d) and c:IsMonster() and c:IsAbleToHand()
end

function s.tgma(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.filterma, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.opms(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.filterma, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- 새로운 조건: 묘지에 튜너와 튜너 이외의 몬스터가 있을 때만 발동 가능
function s.target5(e, tp, eg, ep, ev, re, r, rp, chk)
	 if chk == 0 then
		return Duel.IsExistingMatchingCard(Card.IsType, tp, LOCATION_GRAVE, 0, 1, nil, TYPE_TUNER)
			and Duel.IsExistingMatchingCard(function(c) return not c:IsType(TYPE_TUNER) and not c:IsCode(128770008) end, tp, LOCATION_GRAVE, 0, 1, nil)
	end
	Duel.SetPossibleOperationInfo(0, CATEGORY_REMOVE, nil, 2, tp, LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.filter15(c, e, tp)
	return c:IsType(TYPE_SYNCHRO) and c:GetLevel() < 9
		and (Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0 or Duel.IsPlayerAffectedByEffect(e:GetHandlerPlayer(), 69832741))
		and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SYNCHRO, tp, false, false)
		and Duel.IsExistingMatchingCard(s.filter25, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, 1, nil, e, tp, c)
end

function s.filter25(c, e, tp, sc)
	local rg = Duel.GetMatchingGroup(s.filter35, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, c)
	return c:IsType(TYPE_TUNER) and c:IsAbleToRemove() and aux.SpElimFilter(c, true)
		and aux.SelectUnselectGroup(rg, e, tp, nil, nil, s.rescon5(c, sc), 0)
end

function s.rescon5(tuner, scard)
	return function(sg, e, tp, mg)
		sg:AddCard(tuner)
		local res = Duel.GetLocationCountFromEx(tp, tp, sg, scard) > 0
			and sg:CheckWithSumEqual(Card.GetLevel, scard:GetLevel(), #sg, #sg)
		sg:RemoveCard(tuner)
		return res
	end
end

function s.filter35(c)
	return c:HasLevel() and not c:IsType(TYPE_TUNER) and c:IsAbleToRemove() and aux.SpElimFilter(c, true)
end

function s.activate5(e, tp, eg, ep, ev, re, r, rp)
	local pg = aux.GetMustBeMaterialGroup(tp, Group.CreateGroup(), tp, nil, nil, REASON_SYNCHRO)
	if #pg <= 0 and Duel.IsExistingMatchingCard(s.filter15, tp, LOCATION_EXTRA, 0, 1, nil, e, tp) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local g1 = Duel.SelectMatchingCard(tp, s.filter15, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
		local sc = g1:GetFirst()
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
		local g2 = Duel.SelectMatchingCard(tp, s.filter25, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, 1, 1, nil, e, tp, sc)
		local tuner = g2:GetFirst()
		local rg = Duel.GetMatchingGroup(s.filter35, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, tuner)
		local sg = aux.SelectUnselectGroup(rg, e, tp, nil, nil, s.rescon5(tuner, sc), 1, tp, HINTMSG_REMOVE, s.rescon5(tuner, sc))
		sg:AddCard(tuner)
		Duel.Remove(sg, POS_FACEUP, REASON_EFFECT)
		Duel.SpecialSummon(sc, SUMMON_TYPE_SYNCHRO, tp, tp, false, false, POS_FACEUP)
		sc:CompleteProcedure()
	end
end
