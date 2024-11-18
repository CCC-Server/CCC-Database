local s, id = GetID()
function s.initial_effect(c)
	-- Activate: Fusion Summon
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1=Fusion.CreateSummonEff(c,aux.FilterBoolFunction(Card.IsSetCard,0x30d),aux.FALSE,s.fextra,nil,nil,s.stage2,2,nil,nil,nil,nil,nil,nil,s.extratg)
	c:RegisterEffect(e1)
	c:RegisterEffect(e1)

	-- Substitute destruction
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, {id, 1})
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToGrave),tp,LOCATION_DECK,0,nil)
end


-- Substitute destruction
function s.repfilter(c, tp)
	return c:IsFaceup() and c:IsLocation(LOCATION_MZONE) and c:IsControler(tp) and c:IsSetCard(0x30d)
		and not c:IsReason(REASON_REPLACE) and (c:IsReason(REASON_BATTLE) or (c:IsReason(REASON_EFFECT) and c:GetReasonPlayer() == 1 - tp))
end

function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsAbleToRemove() and eg:IsExists(s.repfilter, 1, nil, tp) end
	return Duel.SelectEffectYesNo(tp, c, 96)
end

function s.repval(e, c)
	return s.repfilter(c, e:GetHandlerPlayer())
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Remove(e:GetHandler(), POS_FACEUP, REASON_EFFECT)
end


