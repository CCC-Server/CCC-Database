--차원감옥 플로렌스
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_DISABLE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetTarget(s.distg)
	c:RegisterEffect(e3)
	--Their activated effects are negated
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_CHAIN_SOLVING)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCondition(s.discon)
	e4:SetOperation(function(_,_,_,_,ev) Duel.NegateEffect(ev) end)
	c:RegisterEffect(e4)
end

function s.filter(c,tp)
	return c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0xda2) and ((c:GetCode()==124331031 and s.mirtg(tp)) or (c:GetCode()==124331032 and s.restg(tp)) or (c:GetCode()==124331033 and s.poltg(tp)))
end

function s.mirtg(tp)
	return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) and Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0
end

function s.opfilter(c)
	return (c:IsLocation(LOCATION_GRAVE) and c:IsMonster()) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup())
end

function s.restg(tp)
	return Duel.IsExistingTarget(s.opfilter,tp,0,LOCATION_GRAVE+LOCATION_EXTRA,1,nil) and Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0
end

function s.poltg(tp)
	return Duel.GetFieldGroupCount(tp,0,LOCATION_EXTRA)>0 and Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil,tp)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tar=Duel.GetFirstTarget()
	if tar:IsRelateToEffect(e) and tar:IsFaceup() then
		local cd=tar:GetCode()
		if cd==124331031 then
			if Duel.GetLocationCount(1-tp,LOCATION_SZONE)==0 then return end
			if not Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) then return end
			local tc=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
			if Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true) then
				--Treated as a Continuous Spell
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetCode(EFFECT_CHANGE_TYPE)
				e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
				e1:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
				tc:RegisterEffect(e1)
			end
		end
		if cd==124331032 then
			if not Duel.IsExistingTarget(s.opfilter,tp,0,LOCATION_GRAVE+LOCATION_EXTRA,1,nil) then return end
			if Duel.GetLocationCount(1-tp,LOCATION_SZONE)==0 then return end
			local tc=Duel.SelectMatchingCard(tp,s.opfilter,tp,0,LOCATION_GRAVE+LOCATION_EXTRA,1,1,nil):GetFirst()
			if Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true) then
				--Treated as a Continuous Spell
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetCode(EFFECT_CHANGE_TYPE)
				e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
				e1:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
				tc:RegisterEffect(e1)
			end
		end
		if cd==124331033 then
			if Duel.GetLocationCount(1-tp,LOCATION_SZONE)==0 then return end
			local g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
			if #g==0 then return end
			Duel.ConfirmCards(tp,g)
			local tc=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_EXTRA,1,1,nil):GetFirst()
			if Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true) then
				--Treated as a Continuous Spell
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetCode(EFFECT_CHANGE_TYPE)
				e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
				e1:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
				tc:RegisterEffect(e1)
			end
			Duel.ShuffleExtra(1-tp)
		end
	end
end
function s.checkfilter(c)
	return c:IsFaceup() and c:IsOriginalType(TYPE_MONSTER) and c:IsContinuousSpell()
end
function s.distg(e,c)
	local eqg=Duel.GetMatchingGroup(s.checkfilter,e:GetHandlerPlayer(),LOCATION_SZONE,LOCATION_SZONE,nil)
	return eqg:IsExists(Card.IsOriginalCodeRule,1,nil,c:GetOriginalCodeRule())
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local eqg=Duel.GetMatchingGroup(s.checkfilter,tp,LOCATION_SZONE,LOCATION_SZONE,nil)
	return re:IsMonsterEffect() and eqg:IsExists(Card.IsOriginalCodeRule,1,nil,re:GetHandler():GetOriginalCodeRule())
end