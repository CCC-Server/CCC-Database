--Gibson Les Paul Junior Double Cut 
local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCost(s.negcost)
	e3:SetCondition(s.negcon)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	local e3b=Effect.CreateEffect(c)
	e3b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e3b:SetRange(LOCATION_SZONE)
	e3b:SetCondition(s.getcon)
	e3b:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3b:SetTarget(function(e,c) return e:GetHandler():GetEquipTarget()==c end)
	e3b:SetLabelObject(e3)
	c:RegisterEffect(e3b)
end
s.listed_names={128101000,1228101005}
function s.spfilter(c,e,tp,code)
	return c:IsSetCard(0xc40) and not c:IsOriginalCode(code) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and e:GetHandler():CheckEquipTarget(c)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local eqc=e:GetHandler():GetEquipTarget()
	if chk==0 then return eqc and eqc:IsAbleToHand() and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp,eqc:GetOriginalCode()) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,eqc,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)==0 then return end
	local c=e:GetHandler()
	local eqc=c:GetEquipTarget()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp,eqc:GetOriginalCode())
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		local eq=g:GetFirst()
		if Duel.Equip(tp,c,eq) and eqc:IsFaceup() and eqc:IsAbleToHand() then
			Duel.BreakEffect()
			Duel.SendtoHand(eqc,nil,REASON_EFFECT)
		end
	end
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetEquipGroup():Filter(Card.IsControler,nil,tp):IsExists(Card.IsAbleToGraveAsCost,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=e:GetHandler():GetEquipGroup():Filter(Card.IsControler,nil,tp):FilterSelect(tp,Card.IsAbleToGraveAsCost,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER) and rp==1-tp
end
function s.hitori(c)
	return c:IsFaceup() and c:IsCode(128101000)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_CONTROL,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if Duel.NegateEffect(ev) and rc:IsRelateToEffect(re) then
		if Duel.IsExistingMatchingCard(s.hitori,tp,LOCATION_ONFIELD,0,1,nil) and rc:IsLocation(LOCATION_MZONE) and rc:IsAbleToChangeControler() and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.GetControl(rc,tp,PHASE_END,1)
		else
			Duel.Destroy(rc,REASON_EFFECT)
		end
	end
end
function s.getcon(e)
	local c=e:GetHandler():GetEquipTarget()
	return c:IsCode(128101005) or (c:IsSetCard(0xc40) and c:IsType(TYPE_FUSION))
end