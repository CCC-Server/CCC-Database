--테이베르스-꽃의 여왕 블라섬
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc03),1,1,Synchro.NonTunerEx(Card.IsSetCard, 0xc03),1,1)
	c:EnableReviveLimit()
	--Your opponent cannot activate Spell/Trap Cards that were not Set
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,1)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) end)
	e1:SetValue(function(e,re,tp) return re:IsHasType(EFFECT_TYPE_ACTIVATE) and not re:GetHandler():IsLocation(LOCATION_SZONE) end)
	c:RegisterEffect(e1)
end

s.listed_series={0xc03}