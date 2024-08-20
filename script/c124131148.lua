--사신 아바타-흑의 불사조
local s,id=GetID()
function s.initial_effect(c)
	--Change its name to "Gunkan Suship Shari"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
	e1:SetValue(21208154)
	c:RegisterEffect(e1)
	--Summon with 3 tribute
	local e1=aux.AddNormalSummonProcedure(c,true,false,3,3)
	local e2=aux.AddNormalSetProcedure(c,true,false,3,3)
	--Cannot be Special Summoned
	local e3=Effect.CreateEffect(c)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e3)
	--Increase its own ATK
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_SET_ATTACK_FINAL)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_REPEAT+EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.adval)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_SET_DEFENSE_FINAL)
	c:RegisterEffect(e5)
	--remove
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_SINGLE)
	e6:SetCode(EVENT_SUMMON_SUCCESS)
	e6:SetTarget(s.rmtg)
	e6:SetOperation(s.rmop)
	c:RegisterEffect(e6)
	--ATK check
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(id)
	c:RegisterEffect(e7)
end
function s.filter(c)
	return c:IsFaceup() and not (c:IsHasEffect(id) or c:IsHasEffect(21208154))
end
function s.adval(e,c)
	local g=Duel.GetMatchingGroup(s.filter,0,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g==0 then 
		return 100
	else
		local tg,val=g:GetMaxGroup(Card.GetAttack)
		if not tg:IsExists(aux.TRUE,1,e:GetHandler()) then
			g:RemoveCard(e:GetHandler())
			tg,val=g:GetMaxGroup(Card.GetAttack)
		end
		return val+100
	end
end
function s.rmfilter(c)
	return c:IsAbleToRemove() and (c:IsLocation(LOCATION_ONFIELD) or aux.SpElimFilter(c,false,true))
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetChainLimit(aux.FALSE)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,e:GetHandler())
	Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
end
