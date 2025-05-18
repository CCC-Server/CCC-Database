local s,id=GetID()
function s.initial_effect(c)
	--①: 발동시 덱에서 "몽마경" 몬스터 1장 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--②: 필드 존에서 제외하고 다른 몽마경 카드 발동
  local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id, 1))
e2:SetCategory(CATEGORY_REMOVE)
e2:SetType(EFFECT_TYPE_IGNITION)
e2:SetRange(LOCATION_FZONE)
e2:SetCountLimit(1, {id,1})
e2:SetCost(s.rmcost)
e2:SetTarget(s.fldtg)
e2:SetOperation(s.fldop)
c:RegisterEffect(e2)

	--③: 효과로 벗어났을 때 제외된 몽마경 카드 회수
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetCountLimit(1,id)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCondition(s.thcon3)
	e3:SetTarget(s.thtg3)
	e3:SetOperation(s.thop3)
	c:RegisterEffect(e3)
 --- ① 카드명 "성광의 몽마경"으로 변경 (무효불가/복사불가)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CHANGE_CODE)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_INACTIVATE)
	e4:SetValue(01050355) -- "성광의 몽마경" 코드
	c:RegisterEffect(e4)

	-- ② 카드명에 "암흑의 몽마경" 추가로 취급 (무효불가/복사불가)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_ADD_CODE)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_INACTIVATE)
	e5:SetValue(74665651) -- "암흑의 몽마경" 코드
	c:RegisterEffect(e5)

	-- ③ 발동 효과 (내용 없음, Free Chain)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_ACTIVATE)
	e6:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e6)
end
--①: 발동 시 몽마경 몬스터 서치
function s.filter1(c)
	return c:IsSetCard(0x131) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand() -- "몽마경" 세트코드 예시
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- 제외 코스트
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- 필드 마법 발동 가능 확인
function s.fldfilter(c)
	return (c:IsCode(74665651) or c:IsCode(01050355)) and c:IsType(TYPE_FIELD) and c:GetActivateEffect()
end

function s.fldtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fldfilter,tp,LOCATION_DECK+LOCATION_HAND,0,2,nil)
	end
end

function s.fldop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.fldfilter,tp,LOCATION_DECK+LOCATION_HAND,0,2,2,nil)
	if #g < 2 then return end

	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) -- 자신 필드존 카드 선택
	local g1=g:Select(tp,1,1,nil)
	local tc1=g1:GetFirst()
	g:RemoveCard(tc1)
	local tc2=g:GetFirst()

	local cards = {{tc1, tp}, {tc2, 1 - tp}}
	for _,entry in ipairs(cards) do
		local tc, p = table.unpack(entry)
		local te=tc:GetActivateEffect()
		if not te then return end
		local fc=Duel.GetFieldCard(p,LOCATION_FZONE,0)
		if fc then Duel.SendtoGrave(fc,REASON_RULE) end
		Duel.MoveToField(tc,p,p,LOCATION_FZONE,POS_FACEUP,true)
		Duel.Hint(HINT_CARD,p,tc:GetCode())
		local cost=te:GetCost()
		if cost then cost(te,p,Group.CreateGroup(),0,0,0,0,0) end
		local target=te:GetTarget()
		if target then target(te,p,Group.CreateGroup(),0,0,0,0,0) end
		Duel.BreakEffect()
		local operation=te:GetOperation()
		if operation then operation(te,p,Group.CreateGroup(),0,0,0,0,0) end
	end
end


--③: 제외된 몽마경 카드 회수
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler():IsSetCard(0x131) -- 몽마경 카드 효과로 제외됐을 때
end
function s.thfilter3(c)
	return c:IsSetCard(0x131) and c:IsAbleToHand() and not c:IsCode(id)
end
function s.thtg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and s.thfilter3(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter3,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter3,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop3(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end