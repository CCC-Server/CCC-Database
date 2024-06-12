--역진화체-Water Spider
local s,id=GetID()
function s.initial_effect(c)
	--cannot special summon
	local e0=Effect.CreateEffect(c)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE)
	c:RegisterEffect(e0)
	--summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_TRIBUTE_LIMIT)
	e1:SetValue(s.tlimit)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SUMMON_PROC)
	e2:SetCondition(s.sumcon)
	e2:SetTarget(s.sumtg)
	e2:SetOperation(s.sumop)
	e2:SetValue(SUMMON_TYPE_TRIBUTE)
	c:RegisterEffect(e2)

	--pierce
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e3)
end
function s.tlimit(e,c)
	return not c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.cfilter(c)
	return c:IsReleasable() and c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.sumcon(e,c,minc,zone,relzone,exeff)
	if c==nil then return true end
	if minc>1 or c:IsLevelBelow(4) then return false end
	local tp=c:GetControler()
	local mg=Duel.GetMatchingGroup(s.cfilter,tp,0,LOCATION_MZONE,nil)
	return #mg>=1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk,c,minc,zone,relzone,exeff)
	local mg=Duel.GetMatchingGroup(s.cfilter,tp,0,LOCATION_MZONE,nil)
	local g=aux.SelectUnselectGroup(mg,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_RELEASE,nil,nil,true)
	if g and #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp,c,minc,zone,relzone,exeff)
	local g=e:GetLabelObject()
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON|REASON_MATERIAL)
	g:DeleteGroup()
end

