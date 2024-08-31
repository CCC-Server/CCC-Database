--리젠트 윙
--リーゼント・ウィング
--Regent Wing
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
	--Send "Plaguespreader Zombie" to grave

	--Can be treated as a non-Tuner for a Synchro Summon
end

--Specifically lists "Plaguespreader Zombie"
s.listed_names={33420078}

--Send "Plaguespreader Zombie" to grave

--Can be treated as a non-Tuner for a Synchro Summon