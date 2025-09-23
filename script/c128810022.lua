--검은 교단-맹혈자-혼돈에 잠식된 K
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,3,3,s.ovfilter,aux.Stringid(id,0),3,s.xyzop)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(Cost.DetachFromSelf(1,1,nil))
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1,false,REGISTER_FLAG_DETACH_XMAT)
end
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsCode(id-6)
end
function s.cfilter(c)
	return c:IsDiscardable()
end
function s.xyzop(e,tp,chk,mc)
	if chk==0 then return not Duel.HasFlagEffect(tp,id) and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local tc=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_HAND,0,nil):SelectUnselect(Group.CreateGroup(),tp,false,Xyz.ProcCancellable)
	if tc then
		Duel.SendtoGrave(tc,REASON_DISCARD|REASON_COST)
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,EFFECT_FLAG_OATH,1)
		return true
	else return false end
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc01) and c:IsLevel(3) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end