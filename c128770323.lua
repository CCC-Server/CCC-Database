local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Fusion Materials (for proper Fusion Summon)
	Fusion.AddProcMixN(c,true,true,s.matfilter,2)
Fusion.AddContactProc(c,function(tp) return Duel.GetMatchingGroup(Card.IsAbleToGraveAsCost,tp,LOCATION_ONFIELD,0,nil) end,function(g) Duel.SendtoGrave(g,REASON_COST|REASON_MATERIAL) end,true)
	-- Restriction: Only Fusion or custom method
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- Custom Special Summon (from field/SZONE using 2 Lv4 Fusion)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	e1:SetValue(SUMMON_TYPE_SPECIAL)
	c:RegisterEffect(e1)

	-- (①) Equip this card to a "Nemesis Artifact"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- (②) Destroy opponent’s monsters with ATK ≤ this card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_ONFIELD)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- Fusion Material Filter: Lv4 Fusion "Nemesis Artifact"
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x764,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp) and c:IsLevel(4)
end

-- Summon Restriction
function s.splimit(e,se,sp,st)
	return e:GetHandler():IsLocation(LOCATION_EXTRA)
end

-- Custom Special Summon (필드/SZONE에서 레벨 4 퓨전 2장 묘지로 보내기)
function s.spfilter(c)
	return c:IsSetCard(0x764)
		and c:IsType(TYPE_FUSION)
		and c:IsLevel(4)
		and c:IsOriginalType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
		and (
			(c:IsFaceup() and c:IsLocation(LOCATION_MZONE)) or
			(c:IsLocation(LOCATION_SZONE) and bit.band(c:GetOriginalType(),TYPE_MONSTER)~=0)
		)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetMatchingGroupCount(s.spfilter,tp,LOCATION_ONFIELD+LOCATION_SZONE,0,nil)>=2
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_ONFIELD+LOCATION_SZONE,0,2,2,nil)
	for tc in g:Iter() do
		if tc:IsLocation(LOCATION_SZONE) and tc:GetEquipTarget() then
			Duel.CancelChain(tc,REASON_RULE)
		end
	end
	Duel.SendtoGrave(g,REASON_COST)
end

-- (①) Equip to another "Nemesis Artifact" monster
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
function s.eqop(e,tp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Equip(tp,c,tc)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetValue(TYPE_SPELL+TYPE_EQUIP)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EQUIP_LIMIT)
	e2:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	e2:SetValue(function(e,c) return e:GetOwner()==c end)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetValue(1)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e3)
end

-- (②) Destroy opponent monsters with ATK ≤ this card's ATK
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsFaceup()
end
function s.desfilter(c,atk)
	return c:IsFaceup() and c:GetAttack()<=atk
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local atk=e:GetHandler():GetAttack()
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,atk)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp)
	local atk=e:GetHandler():GetAttack()
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,atk)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

