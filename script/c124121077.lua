--마도서기 쥬논
local s,id=GetID()
function s.initial_effect(c)
	--①: 패에서 특수 소환하고, 패 / 묘지의 "마도서" 마법 카드를 3장까지 세트
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--②: 마법 카드가 발동했을 때, 필드의 앞면 표시 카드 1장의 효과를 무효
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_CHAINING)
	e2:SetCondition(s.discon)
	e2:SetCost(s.discost)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
end
--①
function s.setfilter(c)
	return c:IsSpell() and c:IsSetCard(0x106e) and c:IsSSetable(true)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
--필드 마법은 필드 존, 그 외는 마법 & 함정 존의 빈 칸 수만큼만 고를 수 있도록
function s.rescon(sg,e,tp,mg)
	local fct=sg:FilterCount(Card.IsType,nil,TYPE_FIELD)
	return fct<=1 and #sg-fct<=Duel.GetLocationCount(tp,LOCATION_SZONE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.setfilter),tp,LOCATION_HAND|LOCATION_GRAVE,0,nil)
	if #g==0 then return end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,3,s.rescon,1,tp,HINTMSG_SET)
	if #sg==0 then return end
	Duel.BreakEffect()
	--서로 확인한다
	local confirmg,hintg=sg:Split(Card.IsLocation,nil,LOCATION_HAND)
	if #confirmg>0 then Duel.ConfirmCards(1-tp,confirmg) end
	if #hintg>0 then Duel.HintSelection(hintg) end
	--자신 필드에 세트
	if Duel.SSet(tp,sg)==0 then return end
	if #confirmg>0 then Duel.ShuffleHand(tp) end
	--세트한 속공 마법 카드는 세트한 턴에도 발동할 수 있다
	for sc in sg:Iter() do
		if sc:IsQuickPlaySpell() and sc:IsLocation(LOCATION_SZONE) and sc:IsFacedown() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
			e1:SetReset(RESETS_STANDARD_PHASE_END)
			sc:RegisterEffect(e1)
		end
	end
end
--②
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and re:IsActiveType(TYPE_SPELL) and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
function s.tgfilter(c,cc)
	return c:IsSpell() and c:IsSetCard(0x106e) and (c:IsLocation(LOCATION_HAND) or c:IsFaceup()) and c:IsAbleToGraveAsCost()
		and Duel.IsExistingTarget(Card.IsNegatable,0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,Group.FromCards(c,cc)+c:GetEquipGroup())
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND|LOCATION_SZONE,0,1,nil,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND|LOCATION_SZONE,0,1,1,nil,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsOnField() and chkc:IsNegatable() and chkc~=c end
	if chk==0 then return Duel.IsExistingTarget(Card.IsNegatable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsNegatable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,c)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=Duel.GetFirstTarget()
	if tc:IsNegatable() and tc:IsRelateToEffect(e) then
		tc:NegateEffects(e:GetHandler(),nil,true)
	end
end
