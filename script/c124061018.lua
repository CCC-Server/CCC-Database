--大霊術－「一流」
Duel.LoadScript("strings.lua") --구현 완료되면 삭제
Duel.LoadScript("archetype_Crowel.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Add attribute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetCode(EFFECT_ADD_ATTRIBUTE)
	e2:SetValue(s.attval)
	c:RegisterEffect(e2)
	--equip
	c:UnimplementedPartially() --구현 완료되면 삭제
end
s.listed_series={0x14d}
--Charmer/Possessed
function s.cpfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)
	and (c:GetBaseAttack()==1850 or (c:GetBaseAttack()==500 and c:GetBaseDefense()==1500))
end
function s.attval(e,c)
	return Duel.GetMatchingGroup(s.cpfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil):GetBitwiseOr(Card.GetOriginalAttribute)
end
