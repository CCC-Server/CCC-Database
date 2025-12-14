local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Fusion Material: 1 Fusion Lv4 + 1 Link (for proper Fusion Summon)
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)
Fusion.AddContactProc(c,function(tp) return Duel.GetMatchingGroup(Card.IsAbleToGraveAsCost,tp,LOCATION_ONFIELD,0,nil) end,function(g) Duel.SendtoGrave(g,REASON_COST|REASON_MATERIAL) end,true)

	-- Must be properly summoned from Extra Deck
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- Special Summon from field/SZONE using specific materials
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- (①) Equip to another "Nemesis Artifact" monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- (②) Destroy on Special Summon from opponent during Main Phase & recover
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_ONFIELD)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end
-- Fusion Material Filters
function s.matfilter1(c,fc,sumtype,tp) 
	return c:IsSetCard(0x764,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp) and c:IsLevel(4)
end
function s.matfilter2(c,fc,sumtype,tp) 
	return c:IsSetCard(0x764,fc,sumtype,tp) and c:IsType(TYPE_LINK,fc,sumtype,tp)
end
-- Summon Restriction
function s.splimit(e,se,sp,st)
	return e:GetHandler():IsLocation(LOCATION_EXTRA)
end

-- Custom Special Summon Condition & Operation
-- Lv4 Fusion Monster ("Nemesis Artifact")
-- Lv4 Fusion Monster ("Nemesis Artifact")
function s.spfilter1(c,fc,sumtype,tp) 
	return c:IsSetCard(0x764)
		and c:IsType(TYPE_FUSION)
		and c:IsLevel(4)
		and c:IsAbleToGraveAsCost()
		and (
			(c:IsFaceup() and c:IsLocation(LOCATION_MZONE)) or
			(c:IsLocation(LOCATION_SZONE) and bit.band(c:GetOriginalType(), TYPE_MONSTER)~=0)
		)
end

-- Link Monster ("Nemesis Artifact")
function s.spfilter2(c,fc,sumtype,tp) 
	return c:IsSetCard(0x764)
		and c:IsType(TYPE_LINK)
		and c:IsAbleToGraveAsCost()
		and (
			(c:IsFaceup() and c:IsLocation(LOCATION_MZONE)) or
			(c:IsLocation(LOCATION_SZONE) and bit.band(c:GetOriginalType(), TYPE_MONSTER)~=0)
		)
end

-- Special Summon condition
function s.spcon(e,c)
	if c==nil then return true end
	local tp = c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,nil)
	   and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,nil)
end

-- Special Summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,1,nil)
	g1:Merge(g2)

	-- 마함존 카드가 장착 상태라면 체인을 해제
	for tc in g1:Iter() do
		if tc:IsLocation(LOCATION_SZONE) and tc:GetEquipTarget() then
			Duel.CancelChain(tc,REASON_RULE)
		end
	end

	Duel.SendtoGrave(g1,REASON_COST)
end


-- (①) Equip to a "Nemesis Artifact" monster
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

-- (②) Destroy opponent's Special Summoned monster & recover
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()>=PHASE_MAIN1 and Duel.GetCurrentPhase()<=PHASE_MAIN2
		and eg:IsExists(s.desfilter,1,nil,tp)
		and e:GetHandler():IsFaceup()
end
function s.desfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsSummonType(SUMMON_TYPE_SPECIAL)
		and c:IsType(TYPE_EFFECT)
		and c:IsLocation(LOCATION_MZONE)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.desfilter,nil,tp)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,g:GetSum(Card.GetAttack))
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.desfilter,nil,tp):Filter(Card.IsOnField,nil)
	if #g>0 then
		local atk=g:GetSum(Card.GetAttack)
		if Duel.Destroy(g,REASON_EFFECT)>0 and atk>0 then
			Duel.Recover(tp,atk,REASON_EFFECT)
		end
	end
end
