local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Fusion Materials (used if Fusion Summoned via spell)
	Fusion.AddProcMixN(c,true,true,s.fusfilter1,1,s.fusfilter2,2)
Fusion.AddContactProc(c,function(tp) return Duel.GetMatchingGroup(Card.IsAbleToGraveAsCost,tp,LOCATION_ONFIELD,0,nil) end,function(g) Duel.SendtoGrave(g,REASON_COST|REASON_MATERIAL) end,true)
	-- Summon restriction: Must be properly summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- Special Summon from Extra Deck by sending field/SZONE materials
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ① Equip to a "Nemesis Artifact" monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- ② Negate from hand/GY/banished and inflict 2000
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DISABLE+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_ONFIELD)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

-- Fusion Material Filters
function s.fusfilter1(c,fc,sumtype,tp) 
	return c:IsSetCard(0x764,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp) and c:IsLevel(4)
end
function s.fusfilter2(c,fc,sumtype,tp) 
	return c:IsSetCard(0x764,fc,sumtype,tp) and c:IsType(TYPE_LINK,fc,sumtype,tp)
end

-- Summon Restriction
function s.splimit(e,se,sp,st)
	return e:GetHandler():IsLocation(LOCATION_EXTRA)
end

-- Custom Special Summon Filters
function s.spfilter_fusion(c)
	return c:IsSetCard(0x764)
		and c:IsOriginalType(TYPE_MONSTER)
		and c:IsType(TYPE_FUSION)
		and c:GetOriginalLevel()==4
		and c:IsAbleToGraveAsCost()
		and ((c:IsLocation(LOCATION_MZONE) and c:IsFaceup())
			or (c:IsLocation(LOCATION_SZONE) and c:IsType(TYPE_SPELL)))
end

function s.spfilter_link(c)
	return c:IsSetCard(0x764)
		and c:IsOriginalType(TYPE_MONSTER)
		and c:IsType(TYPE_LINK)
		and c:IsAbleToGraveAsCost()
		and ((c:IsLocation(LOCATION_MZONE) and c:IsFaceup())
			or (c:IsLocation(LOCATION_SZONE) and c:IsType(TYPE_SPELL)))
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(s.spfilter_fusion,tp,LOCATION_ONFIELD+LOCATION_SZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter_link,tp,LOCATION_ONFIELD+LOCATION_SZONE,0,nil)
	return #g1>=1 and #g2>=2
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter_fusion,tp,LOCATION_ONFIELD+LOCATION_SZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter_link,tp,LOCATION_ONFIELD+LOCATION_SZONE,0,2,2,nil)
	g1:Merge(g2)

	for tc in g1:Iter() do
		if tc:IsLocation(LOCATION_SZONE) and tc:GetEquipTarget() then
			Duel.CancelChain(tc,REASON_RULE)
		end
	end

	Duel.SendtoGrave(g1,REASON_COST)
end

-- ① Equip to "Nemesis Artifact"
function s.eqfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x764)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local tc=Duel.GetFirstTarget()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,c,tc)

		-- Change to Equip Spell
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(TYPE_SPELL+TYPE_EQUIP)
		c:RegisterEffect(e1)

		-- Equip Limit
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_EQUIP_LIMIT)
		e2:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetValue(function(e,c) return e:GetOwner()==c end)
		c:RegisterEffect(e2)

		-- Indestructible while equipped
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e3:SetRange(LOCATION_SZONE)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		e3:SetValue(1)
		c:RegisterEffect(e3)
	end
end

-- ② Negate from hand/GY/banished and inflict 2000
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return (loc==LOCATION_HAND or loc==LOCATION_GRAVE or loc==LOCATION_REMOVED)
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainDisablable(ev)
		and e:GetHandler():IsFaceup()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,2000)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Damage(1-tp,2000,REASON_EFFECT)
	end
end

