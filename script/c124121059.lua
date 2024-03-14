-- 골디네이드 Call-In
local s,id=GetID()
function s.initial_effect(c)
		--destroy
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_ACTIVATE)
		e1:SetCode(EVENT_FREE_CHAIN)
		e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
		e1:SetTarget(s.actcost)
		e1:SetTarget(s.destg)
		e1:SetOperation(s.desop)
		c:RegisterEffect(e1)
		--draw
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetType(EFFECT_TYPE_ACTIVATE)
		e2:SetCode(EVENT_FREE_CHAIN)
		e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
		e2:SetTarget(s.actcost)
		e2:SetTarget(s.drtg)
		e2:SetOperation(s.drop)
		c:RegisterEffect(e2)
end
s.listed_series={0x158,0x17b,0x181}
function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_SZONE,1,nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_SZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_SZONE,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end