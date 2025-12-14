local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Fusion Summon procedure
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)

	-- Special Summon condition: only Fusion or own procedure
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- Special Summon procedure: send required cards from field
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- (①) Equip self to "Nemesis Artifact" monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- (②) Negate opponent's monster effect and Special Summon self from S/T zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_ONFIELD)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- (③) On Special Summon: equip 1 "Nemesis Artifact" Link monster from GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_EQUIP)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetTarget(s.eq2tg)
	e4:SetOperation(s.eq2op)
	c:RegisterEffect(e4)
end

-- Fusion materials
function s.matfilter1(c)
	return c:IsSetCard(0x764) and not c:IsType(TYPE_LINK)
end
function s.matfilter2(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_LINK)
end

-- Summon limit
function s.splimit(e,se,sp,st)
	return e:GetHandler():IsLocation(LOCATION_EXTRA)
end

-- Special Summon by sending correct materials from field (includes SZONE)
function s.spfilter1(c)
	return c:IsSetCard(0x764)
		and c:IsOriginalType(TYPE_MONSTER)
		and not c:IsType(TYPE_LINK)
		and c:IsAbleToGraveAsCost()
		and c:IsFaceup()
end
function s.spfilter2(c)
	return c:IsSetCard(0x764)
		and c:IsOriginalType(TYPE_MONSTER)
		and c:IsType(TYPE_LINK)
		and c:IsAbleToGraveAsCost()
		and c:IsFaceup()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_ONFIELD,0,1,1,nil)
	g1:Merge(g2)
	Duel.SendtoGrave(g1,REASON_COST)
end

-- E1: Equip self to "Nemesis Artifact" monster
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
		-- Change type to Equip Spell
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(TYPE_SPELL+TYPE_EQUIP)
		c:RegisterEffect(e1)

		-- Equip Limit: only to specific monster
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_EQUIP_LIMIT)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetValue(function(e,c) return c:IsSetCard(0x764) end)
		e2:SetLabelObject(tc)
		c:RegisterEffect(e2)
	end
end


-- E2: Negate opponent's monster effect + Special Summon self
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- E3: On Special Summon, equip 1 "Nemesis Artifact" Link monster from GY
function s.eq2filter(c,tp)
	return c:IsSetCard(0x764) and c:IsType(TYPE_LINK) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end
function s.eq2tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.eq2filter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.eq2filter,tp,LOCATION_GRAVE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eq2filter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
end
function s.eq2op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local c=e:GetHandler()
	if tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) then
		Duel.Equip(tp,tc,c)
	end
end
