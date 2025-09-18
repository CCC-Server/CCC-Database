--slipknot - #0 시드 윌슨
function c128220048.initial_effect(c)
		--link material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.hspcon)
	e2:SetTarget(s.hsptg)
	e2:SetOperation(s.hspop)
	c:RegisterEffect(e2)
end
function s.hspfilter(c,tp,sc)
	return (c:IsCode(128220000)) and Duel.GetLocationCountFromEx(tp,tp,c,sc)>0 and c:IsAbleToGraveAsCost()
end
function s.hspcon(e,c)
	if not c then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_ONFIELD,0,2,nil,tp,e:GetHandler()) 
end
function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local tp=c:GetControler()
	local g=Duel.SelectMatchingCard(tp,s.hspfilter,tp,LOCATION_ONFIELD,0,2,2,nil,tp,e:GetHandler())
	if not g then return false end
	g:KeepAlive()
	e:SetLabelObject(g)
	return true
end
function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoGrave(g,REASON_COST)
	g:DeleteGroup()
end