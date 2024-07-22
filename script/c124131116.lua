--포레드런 나이트 폴른 솔저
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon Procedure
	Xyz.AddProcedure(c,nil,3,2)
	--Prevents search
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_TO_HAND)
	e3:SetCondition(s.con)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_DECK)
	c:RegisterEffect(e3)
end

function s.confilter(c)
	return c:IsFaceup() and (c:IsLevelAbove(5) or c:IsRankAbove(5) or c:IsLinkAbove(3))
end

function s.con(e)
	return Duel.IsExistingMatchingCard(s.confilter,e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil)
end
