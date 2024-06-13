--〈영원한 후일담〉 브레이크타임
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.costfilter(c)
	return c:IsRace(RACE_ZOMBIE) and c:IsType(TYPE_NORMAL)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,s.costfilter,1,false,nil,nil) end
	local g=Duel.SelectReleaseGroupCost(tp,s.costfilter,1,1,false,nil,nil)
	e:SetLabelObject(g:GetFirst())
	Duel.Release(g,REASON_COST)
	g:GetFirst():RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,0,0)
end

function s.targetfilter(c)
	return c:IsAbleToGrave()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.targetfilter,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.targetfilter,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_TOGRAVE)
		Duel.SendtoGrave(sg,REASON_EFFECT)
	end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetLabelObject(e:GetLabelObject())
	e1:SetOperation(s.thop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if g:HasFlagEffect(id) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and g:IsCanBeSpecialSummoned(e,0,tp,tp,false,false,POS_FACEUP) and (g:IsLocation(LOCATION_GRAVE) or g:IsLocation(LOCATION_REMOVED) or (g:IsLocation(LOCATION_EXTRA) and g:IsFaceup())) then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
