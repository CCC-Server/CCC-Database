local s,id=GetID()
function s.initial_effect(c)
	--①: 덱복귀 + 데미지	
   local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.operation1)
	c:RegisterEffect(e1)

	--②: 제외되었을 때 - 상대 필드 1장 → 패
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.excon2)
	e2:SetTarget(s.extg2)
	e2:SetOperation(s.exop2)
	c:RegisterEffect(e2)

	--③: LP 2000 이하, 상대 효과 발동시 → 효과 데미지 0
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.damcon3)
	e3:SetCost(s.damcost3)
	e3:SetOperation(s.damop3)
	c:RegisterEffect(e3)
end

-----------------------------------
-- ①: LP 절반 + 덱 복귀 + 데미지
-----------------------------------
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,math.floor(Duel.GetLP(tp)/2)) end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end
function s.filter1(c,lp)
	return c:IsFaceup() and c:GetAttack()>=lp and c:IsAbleToDeck()
end
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local lp=Duel.GetLP(tp)
	local max=1
	if lp<=250 then max=2 end
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter1,tp,0,LOCATION_MZONE,1,nil,lp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.filter1,tp,0,LOCATION_MZONE,1,max,nil,lp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0) -- 데미지는 후에 처리
	e:SetLabel(lp)
end
function s.operation1(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	local total_dmg=0
	for tc in aux.Next(g) do
		if tc:IsRelateToEffect(e) then
			local atk=tc:GetBaseAttack()
			if Duel.SendtoDeck(tc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)>0 then
				total_dmg=total_dmg+atk
			end
		end
	end
	if total_dmg>0 then
		Duel.Damage(1-tp,total_dmg,REASON_EFFECT)
	end
end

-----------------------------------
-- ②: 제외 → 상대 필드 카드 1장 → 패
-----------------------------------
function s.excon2(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler():IsSetCard(0x175) and re:GetHandler():IsMonster()
end
function s.extg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.exop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end

-----------------------------------
-- ③: LP2000 이하 & 상대 효과 발동 → 효과 데미지 0
-----------------------------------
function s.damcon3(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp)<=2000 and rp==1-tp
end
function s.damcost3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end
function s.damop3(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_NO_EFFECT_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
