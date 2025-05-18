--Dreammirror Tactics
local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드의 발동은 패에서도 가능
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	-- 발동 시 ①의 효과: 묘지의 몽마경 카드 1장 덱으로 되돌리고 상대 카드 효과 무효
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.effectcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 묘지에서 ②의 효과: 자신/상대 턴에 다른 몽마경 일반 함정 효과 복사
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(aux.exccon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.copytg)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)

	-- 발동 제한: 이 카드명의 ①② 효과는 1개만 사용 가능
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.chainfilter)
end

-- 패 발동 조건: 자신 필드에 성광/암흑의 몽마경 존재 시
function s.handcon(e)
	return Duel.IsExistingMatchingCard(s.fieldfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
function s.fieldfilter(c)
	return c:IsFaceup() and (c:IsCode(74665651) or c:IsCode(01050355)) -- 성광/암흑의 몽마경 카드 번호
end

-- 효과 발동 제한 체크: ①② 중 하나만
function s.chainfilter(re,tp,cid)
	return re:GetHandler():IsCode(id)
end
function s.effectcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)==0
end

-- ① 효과 대상: 묘지 몽마경 1장 + 상대 필드 카드 1장
function s.tdfilter(c)
	return c:IsSetCard(0x131) and c:IsAbleToDeck()
end
function s.negfilter(c)
	return c:IsFaceup() and aux.disfilter1(c)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g2=Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g2,1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local td=tg:Filter(Card.IsLocation,nil,LOCATION_GRAVE):GetFirst()
	local dis=tg:Filter(Card.IsLocation,nil,LOCATION_ONFIELD):GetFirst()
	if td and td:IsRelateToEffect(e) then
		Duel.SendtoDeck(td,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	if dis and dis:IsRelateToEffect(e) and dis:IsFaceup() and not dis:IsDisabled() then
		Duel.NegateRelatedChain(dis,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		dis:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		dis:RegisterEffect(e2)
	end
end

-- ② 효과: 덱에서 몽마경 일반 함정 묘지로 보내고 그 효과 복사
function s.copyfilter(c)
	return c:IsSetCard(0x131) and c:IsType(TYPE_TRAP) and c:IsAbleToGrave()
		and c:CheckActivateEffect(false,true,false)~=nil
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tc=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if not tc then return end
	local te=tc:CheckActivateEffect(false,true,true)
	if Duel.SendtoGrave(tc,REASON_EFFECT)==0 or not te then return end
	e:GetHandler():CreateEffectRelation(te)
	if te:GetTarget() then te:GetTarget()(e,tp,eg,ep,ev,re,r,rp,1) end
	if te:GetOperation() then te:GetOperation()(e,tp,eg,ep,ev,re,r,rp) end
end

