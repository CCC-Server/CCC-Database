--Harpie Rank 7 Xyz (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_WIND),7,2)
	c:EnableReviveLimit()

	--①: On Xyz Summon → Set 1 Harpie Spell/Trap in End Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--②: Change opponent effect to destroy 1 Spell/Trap
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.chcon)
	e2:SetCost(s.chcost)
	e2:SetTarget(s.chtg)
	e2:SetOperation(s.chop)
	c:RegisterEffect(e2)

	--③: Bounce 1 Harpie you control and 1 card on the field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+200)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetTarget(s.rtg)
	e3:SetOperation(s.rop)
	c:RegisterEffect(e3)

	--④: Name becomes "Harpie Lady" on field / GY
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE|LOCATION_GRAVE)
	e4:SetCode(EFFECT_CHANGE_CODE)
	e4:SetValue(CARD_HARPIE_LADY)
	c:RegisterEffect(e4)
end

s.listed_series={SET_HARPIE}
s.listed_names={CARD_HARPIE_LADY,CARD_HARPIE_LADY_SISTERS}

--①: Set effect
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.setfilter(c)
	return (c:ListsCode(CARD_HARPIE_LADY) or c:ListsCode(CARD_HARPIE_LADY_SISTERS))
		and c:IsSpellTrap() and c:IsSSetable()
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetOperation(s.endset)
	Duel.RegisterEffect(e1,tp)
end
function s.endset(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),
		tp,LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then Duel.SSet(tp,g) end
end

--②: Chain Replace Effect
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp then return false end
	local rc=re:GetHandler()
	return (re:IsMonsterEffect()
		or ((rc:IsNormalSpell() or rc:IsNormalTrap()) and re:IsHasType(EFFECT_TYPE_ACTIVATE)))
		and e:GetHandler():GetOverlayGroup():IsExists(Card.IsSetCard,1,nil,SET_HARPIE)
end
function s.chcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ct=c:GetOverlayCount()
	if chk==0 then return ct>0 end
	c:RemoveOverlayCard(tp,ct,ct,REASON_COST)
end
function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end
function s.chop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeTargetCard(ev,Group.CreateGroup()) -- 기존 타겟 무효
	Duel.ChangeChainOperation(ev,s.newop)
end
function s.newop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,Card.IsSpellTrap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then Duel.Destroy(g,REASON_EFFECT) end
end

--③: Bounce
function s.harpiefilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_HARPIE) and c:IsAbleToHand()
end
function s.rtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.harpiefilter(chkc) end
	if chk==0 then
		return Duel.IsExistingTarget(s.harpiefilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	Duel.SelectTarget(tp,s.harpiefilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.rop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then Duel.SendtoHand(g,nil,REASON_EFFECT) end
	end
end
