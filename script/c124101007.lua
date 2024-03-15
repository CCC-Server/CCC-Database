--초전사의 잔향
Duel.LoadScript("archetype_seihai.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,1,1)
	--Cannot be targeted
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.tgcon)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	--Choose battle target
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_PATRICIAN_OF_DARKNESS)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.tgcon)
	c:RegisterEffect(e2)
	--Copy 1 "Super Soldier" Spell/Trap
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCountLimit(1,id)
	e3:SetCost(s.cpcost)
	e3:SetTarget(s.cptg)
	e3:SetOperation(s.cpop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_BLACK_LUSTER_SOLDIER,ARCHETYPE_SUPER_SOLDIER}
--Link Summon
function s.matfilter(c,scard,sumtype,tp)
	return c:IsSetCard(SET_BLACK_LUSTER_SOLDIER,scard,sumtype,tp) and c:IsRitualMonster()
end
--Cannot be targeted
function s.tgfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_BLACK_LUSTER_SOLDIER) and c:IsRitualMonster()
end
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetLinkedGroup():IsExists(s.tgfilter,1,nil)
end
--Copy 1 "Super Soldier" Spell/Trap
function s.cpcost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(1)
	return true
end
function s.cpfilter(c)
	return c:IsSpellTrap() and c:IsArchetype(ARCHETYPE_SUPER_SOLDIER) and c:IsAbleToGraveAsCost()
		and c:CheckActivateEffect(false,true,true)~=nil
end
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if e:GetLabel()==0 then return false end
		e:SetLabel(0)
		return Duel.IsExistingMatchingCard(s.cpfilter,tp,LOCATION_DECK,0,1,nil)
	end
	e:SetLabel(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tc=Duel.SelectMatchingCard(tp,s.cpfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	local te,ceg,cep,cev,cre,cr,crp=tc:CheckActivateEffect(false,true,true)
	Duel.SendtoGrave(tc,REASON_COST)
	e:SetProperty(te:GetProperty())
	local tg=te:GetTarget()
	if tg then tg(e,tp,ceg,cep,cev,cre,cr,crp,1) end
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	Duel.ClearOperationInfo(0)
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then return end
	e:SetLabelObject(te:GetLabelObject())
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end
