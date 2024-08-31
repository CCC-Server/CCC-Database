--리젠트 클로
--リーゼント・クロー
--Regent Claw
local s,id=GetID()
function s.initial_effect(c)
	--Name becomes "Plaguespreader Zombie" while on the field or in the GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE+LOCATION_DECK+LOCATION_HAND)
	e1:SetValue(33420078)
	c:RegisterEffect(e1)
	--Summon 1 "Multiply Token"on controler's field
	
	--Set 1 "Regent" spell / trap card on controler's field
end

--Specifically lists "Plaguespreader Zombie"
s.listed_names={33420078}

--Summon 1 "Multiply Token"on controler's field

--Set 1 "Regent" spell / trap card on controler's field