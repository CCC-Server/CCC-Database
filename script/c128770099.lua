--헤이즈 서포트 일반 마법 (예시 이름: 헤이즈의 소환의식)
local s,id=GetID()
function s.initial_effect(c)
	--①: 덱에서 "헤이즈 비스트" 서치 + 헤이즈 필라/글로리 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	c:RegisterEffect(e1)

	--②: 묘지 제외하고 자신의 헤이즈 비스트에 체인 불가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.cost2)
	e2:SetOperation(s.activate2)
	c:RegisterEffect(e2)
end

--①: 덱에서 헤이즈 비스트 서치 + 헤이즈 필라 or 글로리 발동
function s.thfilter(c)
	return c:IsSetCard(0x107d) and c:IsAbleToHand()
end
function s.setfilter(c)
	return c:IsCode(83108603,43708041) and c:IsSSetable()  -- 헤이즈 필라 or 헤이즈 글로리
end
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	--헤이즈 비스트 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	--헤이즈 필라 또는 글로리 발동
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- "헤이즈 필라 또는 글로리를 선택하세요"
	local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=sg:GetFirst()
	if tc then
		local tpe=tc:GetType()
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		local te=tc:GetActivateEffect()
		if te then
			local tep=tc:GetControler()
			local cost=te:GetCost()
			if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
		end
	end
end

--②: 묘지에서 제외 → 헤이즈 비스트 체인 봉쇄
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return aux.bfgcost(e,tp,eg,ep,ev,re,r,rp,0) end
	aux.bfgcost(e,tp,eg,ep,ev,re,r,rp,1)
end
function s.chainlimit(e,ep,tp)
	return not e:GetHandler():IsSetCard(0x107d)
end
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetValue(function(e,re,tp) return re:IsHasType(EFFECT_TYPE_ACTIVATE+EFFECT_TYPE_QUICK_O+EFFECT_TYPE_QUICK_F+EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_TRIGGER_F) end)
	e1:SetLabelObject(e)
	e1:SetCondition(function(e)
		return Duel.GetCurrentPhase()>=PHASE_MAIN1 and Duel.GetCurrentPhase()<=PHASE_MAIN2
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	--해당 턴 동안 상대는 헤이즈 비스트 효과 발동에 체인 불가
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return rc:IsSetCard(0x107d) and re:IsActiveType(TYPE_MONSTER)
end
