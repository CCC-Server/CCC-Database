--동물귀무녀 카무카카리
--みみこかむかかり
--Mimiko Divine Possesion
local s,id=GetID()
function s.initial_effect(c)
	--Litual Summon 1 Beast Monster
	local e1=Ritual.AddProcEqual(c,aux.FilterBoolFunction(Card.IsRace,RACE_BEAST))
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCountLimit(1,{id,0})
end

--Part of "Mimiko" archetype
s.listed_series={0xda0}