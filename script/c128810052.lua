local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(s.tmatfilter),1,1,Synchro.NonTunerEx(s.ntmatfilter),2,99)
	c:AddMustBeSynchroSummoned()
	Pendulum.AddProcedure(c)
	-- ATK/DEF update
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.adval)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	-- Unaffected by other activated effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)
	-- Change activated effect
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetLabel(0)
	e4:SetCondition(s.chcon)
	e4:SetTarget(s.chtg)
	e4:SetOperation(s.chop)
	c:RegisterEffect(e4)
	-- Store material count
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetLabelObject(e4)
	e5:SetOperation(s.regop)
	c:RegisterEffect(e5)
end

s.listed_series={0xc02}
s.listed_names={id}
s.synchro_tuner_required=1
s.synchro_nt_required=2

function s.tmatfilter(c,scard,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

function s.ntmatfilter(c,scard,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

function s.adfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and (not c:IsLocation(LOCATION_MZONE|LOCATION_EXTRA) or c:IsFaceup())
end

function s.adval(e,c)
	return Duel.GetMatchingGroupCount(s.adfilter,c:GetControler(),LOCATION_EXTRA|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,0,nil)*200
end

function s.efilter(e,te)
	return te:IsActivated() and te:GetHandler()~=e:GetHandler()
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsSummonType(SUMMON_TYPE_SYNCHRO) then return end
	local mg=c:GetMaterial()
	if not mg then return end
	local ct=mg:FilterCount(Card.IsType,nil,TYPE_SYNCHRO)
	e:GetLabelObject():SetLabel(ct)
end

function s.rmfilter(c)
	return c:IsAbleToRemove() and (not c:IsLocation(LOCATION_EXTRA) or c:IsFaceup())
end

function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()
	return rp==1-tp and re:GetHandler()~=c and ct~=nil and c:GetFlagEffect(id+100)<ct
		and (re:IsActiveType(TYPE_MONSTER)
			or (re:IsActiveType(TYPE_SPELL) and re:GetHandler():IsNormalSpell())
			or (re:IsActiveType(TYPE_TRAP) and re:GetHandler():IsNormalTrap()))
end

function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_HAND|LOCATION_GRAVE|LOCATION_EXTRA,0,4,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,4,tp,LOCATION_HAND|LOCATION_GRAVE|LOCATION_EXTRA)
end

function s.repop(p)
	Duel.Hint(HINT_SELECTMSG,p,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(p,s.rmfilter,p,LOCATION_HAND|LOCATION_GRAVE|LOCATION_EXTRA,0,4,4,nil)
	if not g or #g<4 then return end
	Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
end

function s.chop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	c:RegisterFlagEffect(id+100,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,0,1)
	local p=tp
	Duel.ChangeChainOperation(ev,function()
		s.repop(p)
	end)
end
