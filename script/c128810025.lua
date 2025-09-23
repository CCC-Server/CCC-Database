--검은 교단-순혈자-데스페로
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),5,2)
	--dis field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ) end)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.ztg)
	e1:SetOperation(s.zop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCost(Cost.DetachFromSelf(1,1,nil))
	e1:SetCountLimit(1,{id,1})
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
function s.ztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE,PLAYER_NONE,0)+Duel.GetLocationCount(1-tp,LOCATION_MZONE,PLAYER_NONE,0)>0 end
	local dis=Duel.SelectDisableField(tp,1,LOCATION_MZONE,LOCATION_MZONE,0)
	Duel.Hint(HINT_ZONE,tp,dis)
	Duel.SetTargetParam(dis)
end
function s.zop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetOperation(function(e) return e:GetLabel() end)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	e1:SetLabel(Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM))
	c:RegisterEffect(e1)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_SZONE) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_SZONE,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,0))
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_SZONE,1,1,e:GetHandler())
	Duel.SetChainLimit(aux.FALSE)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e)  then
		c:SetCardTarget(tc)
		e:SetLabelObject(tc)
		local e0=Effect.CreateEffect(c)
		e0:SetType(EFFECT_TYPE_SINGLE)
		e0:SetProperty(EFFECT_FLAG_OWNER_RELATE)
		e0:SetCode(EFFECT_CANNOT_TRIGGER)
		e0:SetReset(RESET_EVENT+RESETS_STANDARD)
		e0:SetCondition(s.rcon)
		e0:SetValue(1)
		tc:RegisterEffect(e0)  
		if tc:IsFaceup() then
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetCondition(s.rcon)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			tc:RegisterEffect(e2)
			if tc:IsType(TYPE_TRAPMONSTER) then
				local e3=e1:Clone()
				e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
				tc:RegisterEffect(e3)
			end
		end
	end
end
function s.rcon(e)
	return e:GetOwner():IsHasCardTarget(e:GetHandler())
end