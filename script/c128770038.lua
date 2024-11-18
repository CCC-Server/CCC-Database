local s, id = GetID()
function s.initial_effect(c)
	-- Fusion summon effect
	local e1 = Fusion.CreateSummonEff(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), nil, s.fextra, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, s.extratg)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end
s.listed_series = {0x30d}

function s.fcheck(tp, sg, fc)
	-- Limit the number of cards being considered from Extra Deck and Deck
	return sg:FilterCount(Card.IsLocation, nil, LOCATION_EXTRA + LOCATION_DECK) <= 1
end

function s.fextra(e, tp, mg)
	if Duel.IsExistingMatchingCard(Card.IsSummonLocation, tp, 0, LOCATION_MZONE, 1, nil, LOCATION_EXTRA) then
		-- Limit the group search scope to reduce memory usage
		local eg = Duel.GetMatchingGroup(s.exfilter, tp, LOCATION_DECK, 0, nil)
		if #eg > 0 then
			return eg, s.fcheck
		end
	end
	return nil
end

function s.exfilter(c)
	-- Simplify the filter to reduce processing load
	return c:IsMonster() and c:IsSetCard(0x30d) and c:IsAbleToGrave()
end

function s.extratg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetPossibleOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_DECK)
end
