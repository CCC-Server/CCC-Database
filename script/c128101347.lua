local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------
	-- Xyz Summon
	---------------------------------------
	Xyz.AddProcedure(c,nil,8,4)
	c:EnableReviveLimit()

	---------------------------------------
	-- ① Set 1 "Stellaron Hunter" S/T from Deck or GY
	---------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	---------------------------------------
	-- ② Declare type → Detach → Check top → Negate opponent’s S/T/M
	---------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_ANNOUNCE+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.cost2)
	e2:SetTarget(s.tg2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)

	---------------------------------------
	-- ③ Shuffle up to 3 "Stellaron Hunter" monsters from GY/banish into Deck
	---------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetTarget(s.tg3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)
end

------------------------------------------------------------
-- ① Condition: Only if this card was properly Xyz Summoned
------------------------------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

------------------------------------------------------------
-- ① Search & Set “Stellaron Hunter” Spell/Trap
------------------------------------------------------------
function s.setfilter(c)
	return c:IsSetCard(0xc47) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and Duel.SSet(tp,tc)~=0 then
		-- can activate this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		tc:RegisterEffect(e2)
	end
end

------------------------------------------------------------
-- ② Cost: detach 1
------------------------------------------------------------
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST)
	end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

------------------------------------------------------------
-- ② Declare card type
------------------------------------------------------------
local map_type = {
	[0]=TYPE_MONSTER,
	[1]=TYPE_SPELL,
	[2]=TYPE_TRAP
}

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 end
	Duel.Hint(HINT_SELECTMSG,tp,569)
	local ann=Duel.AnnounceType(tp)
	e:SetLabel(ann)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

------------------------------------------------------------
-- ② Operation
------------------------------------------------------------
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

	local ann=e:GetLabel()
	local typ=map_type[ann]

	-- reveal top card
	Duel.ConfirmDecktop(1-tp,1)
	local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
	if not tc then return end

	local matched = tc:IsType(typ)

	-- negate opponent's declared type on field
	local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,typ)
	for sc in g:Iter() do
		Duel.NegateRelatedChain(sc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		sc:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		sc:RegisterEffect(e2)

		if sc:IsType(TYPE_TRAPMONSTER) then
			local e3=e1:Clone()
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			sc:RegisterEffect(e3)
		end
	end

	-- if matched → draw 1
	if matched then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

------------------------------------------------------------
-- ③ Shuffle up to 3 “Stellaron Hunter” monsters
------------------------------------------------------------
function s.tdfilter(c)
	return c:IsSetCard(0xc47) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeck()
end
function s.tg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.op3(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,
		LOCATION_GRAVE+LOCATION_REMOVED,0,1,3,nil)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end
