--憑依装着
--빙의장착
local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c,nil,s.eqfilter,e)
	--Cannot be Target
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--Update Atk
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(s.con)
	e2:SetValue(1350)
	c:RegisterEffect(e2)
	--Control
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_SET_CONTROL)
	e3:SetValue(function(e) return e:GetHandlerPlayer() end)
	e3:SetCondition(s.contcon)
	c:RegisterEffect(e3)
end
--
function s.eqfilter(c,e)
	return (c:IsRace(RACE_SPELLCASTER) and (c:GetBaseAttack()==1850 or c:GetBaseDefense()==1500) and c:IsControler(e:GetHandlerPlayer())) or c:IsControler(1-e:GetHandlerPlayer()) or (c:IsControler(e:GetHandlerPlayer()) and c:GetEquipGroup():IsExists(Card.IsCode,1,nil,id))
end
--
function s.con(e,c)
	local c=e:GetHandler():GetEquipTarget()
	return c:IsRace(RACE_SPELLCASTER) and (c:GetBaseAttack()==1850 or c:GetBaseDefense()==1500)
end
--
function s.contfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER) and (c:GetBaseAttack()==1850 or c:GetBaseDefense()==1500)
end
function s.contcon(e)
	return Duel.IsExistingMatchingCard(s.contfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end