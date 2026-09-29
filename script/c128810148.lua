--제 9사도-건설자 루크 렉스 루미니스
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환: 레벨 13 몬스터 x5 / 자신 필드의 "제 9사도-건설자 루크" 위에 겹쳐서도 가능
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,13,5,s.ovfilter,aux.Stringid(id,0))

	-- 룰상 "헤블론" 카드로도 취급한다
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(0xc06)
	c:RegisterEffect(e0)

	-- ①: 이 카드를 대상으로 하는 효과 이외의, 상대가 발동한 효과를 받지 않는다
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.immval)
	c:RegisterEffect(e1)

	-- ②: 엑시즈 소재 1개당 공/수 500 상승
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- ③: 상대 마/함 발동시, 소재 3개 제거 -> 발동 무효 + 그 카드를 소재로 한다 (동일 체인 1번까지)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

-- 대체 엑시즈 소재: 자신 필드의 앞면 "제 9사도-건설자 루크"
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsCode(128810143)
end

-- ①: 상대가 발동한 효과는 받지 않는다. 단, 이 카드를 대상으로 하는 효과는 받는다.
function s.immval(e,re)
	local c=e:GetHandler()
	if re:GetOwnerPlayer()~=1-e:GetHandlerPlayer() or not re:IsActivated() then return false end
	if re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
		if tg and tg:IsContains(c) then return false end
	end
	return true
end

-- ②
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

-- ③
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:GetFlagEffect(id)==0 and c:CheckRemoveOverlayCard(tp,3,REASON_COST)
	end
	c:RemoveOverlayCard(tp,3,3,REASON_COST)
	-- 동일한 체인 위에서는 1번까지
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_CHAIN,0,1)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and c:IsRelateToEffect(e) and c:IsFaceup()
		and rc:IsRelateToEffect(re) then
		rc:CancelToGrave()
		Duel.Overlay(c,rc,true)
	end
end