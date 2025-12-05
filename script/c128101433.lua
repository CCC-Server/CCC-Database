-- World Guardian Trap
-- Scripted by Gemini
local s,id=GetID()
function s.initial_effect(c)
	-- (1) Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	-- Fixed: Removed CATEGORY_TOFIELD as it causes errors in some cores
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- Allow activation from hand
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	-- (2) Draw from GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.drcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)

	-- Global check for Extra Deck Special Summons
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end
s.listed_series={0xc52} -- World Guardian

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	for tc in aux.Next(eg) do
		if tc:IsSummonLocation(LOCATION_EXTRA) then
			Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

-- Filter for "World Guardian"
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsReleasable()
end

function s.handcon(e)
	return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if c:IsStatus(STATUS_ACT_FROM_HAND) then
		if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil)
		Duel.Release(g,REASON_COST)
	else
		if chk==0 then return true end
	end
end

function s.fieldfilter(c)
	return c:IsType(TYPE_FIELD) and c:IsSSetable() and not c:IsForbidden()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.fieldfilter,tp,LOCATION_DECK,0,nil)
		return g:GetClassCount(Card.GetCode)>=2
	end
	if Duel.GetFlagEffect(1-tp,id)>0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.fieldfilter,tp,LOCATION_DECK,0,nil)
	if g:GetClassCount(Card.GetCode)<2 then return end
	
	-- Manual selection for compatibility (SelectSubGroup error fix)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	-- 1. Select the first card
	local g1=g:Select(tp,1,1,nil)
	local tc1=g1:GetFirst()
	
	-- 2. Remove cards with the same name from the group
	g:Remove(Card.IsCode,nil,tc1:GetCode())
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	-- 3. Select the second card from the remaining pool
	local g2=g:Select(tp,1,1,nil)
	local tc2=g2:GetFirst()
	
	if not tc1 or not tc2 then return end

	-- Set to Self
	Duel.MoveToField(tc1,tp,tp,LOCATION_FZONE,POS_FACEDOWN,true)
	-- Set to Opponent
	Duel.MoveToField(tc2,tp,1-tp,LOCATION_FZONE,POS_FACEDOWN,true)
	
	-- Check for Extra Deck Summon usage this turn
	if Duel.GetFlagEffect(1-tp,id)>0 then
		local dg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then -- "Destroy 1 card?"
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local des=dg:Select(tp,1,1,nil)
			Duel.Destroy(des,REASON_EFFECT)
		end
	end
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end