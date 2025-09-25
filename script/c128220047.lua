--slipknot - #8 코리 테일러
local s,id=GetID()
function c128220047.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Materials and Special Summon Procedure
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(s.sfilter),s.zombiefilter)
	Fusion.AddContactProc(c,s.contactfil,s.contactop,true)
		--reflect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCode(EFFECT_REFLECT_BATTLE_DAMAGE)
	e1:SetTarget(s.reftg)
	e1:SetValue(1)
	c:RegisterEffect(e1)
end
function s.sfilter(c)
	return c:IsSetCard(0xc22) and c:IsMonster()
end
function s.zombiefilter(c)
	return c:IsRace(RACE_ZOMBIE)
end
function s.contactfil(tp)
	return Duel.GetMatchingGroup(Card.IsAbleToDeckOrExtraAsCost,tp,LOCATION_MZONE|LOCATION_GRAVE,0,nil)
end
function s.contactop(g,tp)
	local fu,fd=g:Split(Card.IsFaceup,nil)
	if #fu>0 then Duel.HintSelection(fu,true) end
	if #fd>0 then Duel.ConfirmCards(1-tp,fd) end
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST|REASON_MATERIAL)
end
function s.reftg(e,c)
	return c:IsSetCard(0xc22)
end