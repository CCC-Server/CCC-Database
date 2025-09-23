--검은 교단-맹혈자-광기의 어둠 제트
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,3,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
	c:EnableReviveLimit()
	--Destroy
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(function() return Duel.IsMainPhase() end)
	e1:SetCost(Cost.DetachFromSelf(1,1,nil))
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1,false,REGISTER_FLAG_DETACH_XMAT)
end
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsCode(id-4)
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
function s.desfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc01)
		and Duel.IsExistingTarget(aux.TRUE,0,0,LOCATION_ONFIELD,1,c)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,g1:GetFirst())
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,#g1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	Duel.Destroy(g,REASON_EFFECT)
end