--憑依装着
--빙의장착
local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c)
	--Charmer/Possessed
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.con)
	e1:SetValue(1350)
	c:RegisterEffect(e1)
	--else
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(aux.NOT(s.con))
	e2:SetValue(-1350)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_DISABLE)
	e3:SetCondition(aux.NOT(s.con))
	c:RegisterEffect(e3)
	--Replace
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	c:RegisterEffect(e4)
	--Equip from banished
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_EQUIP)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_REMOVE)
	e5:SetCondition(s.eqcon)
	e5:SetTarget(s.eqtg)
	e5:SetOperation(s.eqop)
	c:RegisterEffect(e5)
end
--Charmer/Possessed
function s.con(e,c)
	local c=e:GetHandler():GetEquipTarget()
	return ((c:GetBaseAttack()==500 and c:GetBaseDefense()==1500) or c:GetBaseAttack()==1850) and c:IsRace(RACE_SPELLCASTER)
end
--Replace
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsLocation(LOCATION_MZONE)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
	if Duel.SelectEffectYesNo(tp,e:GetHandler(),96) then
		local g=eg:Filter(s.repfilter,nil,tp)
		if #g==1 then
			e:SetLabelObject(g:GetFirst())
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
			local tc=g:Select(tp,1,1,nil):GetFirst()
			e:SetLabelObject(tc)
		end
		e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESET_TODECK+RESET_TOGRAVE+RESET_TOFIELD+RESET_TOHAND,0,1)
		Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
		return true
	else return false end
end
function s.repval(e,c)
	return c==e:GetLabelObject()
end
--Equip from banished
function s.eqcon(e)
	return e:GetHandler():HasFlagEffect(id)
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if c:IsPreviousLocation(LOCATION_GRAVE) then
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then return c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and #g>0 end 
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,c,1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and #g>0 then
		local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_EQUIP):GetFirst()
		Duel.Equip(tp,c,sg)
		if e:GetLabel()==1 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
			e1:SetValue(LOCATION_DECKBOT)
			c:RegisterEffect(e1)
		end
	end
end
