local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------
	-- Xyz Summon Procedure
	---------------------------------------
	Xyz.AddProcedure(c,nil,6,3)
	c:EnableReviveLimit()

	---------------------------------------
	-- Effect ①: Quick effect to destroy declared type
	---------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	---------------------------------------
	-- Effect ②: ATK Boost based on material types
	---------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- Cost: detach 1 material
--------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--------------------------------------------------
-- Target: declare 1 type (Monster/Spell/Trap)
--------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,569) -- 569 = Declare a card type
	local typ=Duel.AnnounceType(tp) -- 0 = Monster, 1 = Spell, 2 = Trap
	e:SetLabel(typ)
end

--------------------------------------------------
-- Operation: destroy all cards of declared type on opponent’s field
--------------------------------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local typ=e:GetLabel()
	local cardtype
	if typ==0 then
		cardtype=TYPE_MONSTER
	elseif typ==1 then
		cardtype=TYPE_SPELL
	else
		cardtype=TYPE_TRAP
	end
	local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,cardtype)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--------------------------------------------------
-- Effect ②: Gain 500 ATK for each card type among Xyz Materials
--------------------------------------------------
function s.atkval(e,c)
	local typemask=0
	local og=c:GetOverlayGroup()
	for tc in og:Iter() do
		typemask=typemask|tc:GetType()
	end
	local ct=0
	if (typemask & TYPE_MONSTER)~=0 then ct=ct+1 end
	if (typemask & TYPE_SPELL)~=0 then ct=ct+1 end
	if (typemask & TYPE_TRAP)~=0 then ct=ct+1 end
	return ct*500
end
