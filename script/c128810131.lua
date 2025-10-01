--보옥의 도시－레인보우 폴리스
local s,id=GetID()
function s.initial_effect(c)
    c:EnableCounterPermit(0x6)
	--발동 (① 효과 포함)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	--② 젬 카운터 올리기
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_MOVE)
	e2:SetRange(LOCATION_FZONE)
    e2:SetCondition(s.ctcon1)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
    local e3=e2:Clone()
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetCondition(s.ctcon2)
	c:RegisterEffect(e3)
	--③ 덱으로 되돌릴 수 없음
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_TO_DECK)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCondition(s.indcon)
	c:RegisterEffect(e4)
	--④ 무효 & 파괴
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_FZONE)
	e5:SetCountLimit(1,{id,1})
	e5:SetCondition(s.negcon)
	e5:SetCost(s.negcost)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
end
s.listed_series={SET_CRYSTAL,SET_CRYSTAL_BEAST} -- 보옥수 / 보옥
s.counter_place_list={0x6}

--① 발동시 처리
function s.thfilter(c)
	return c:IsSetCard(SET_CRYSTAL) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.ctfilter(c)
	return c:IsLocation(LOCATION_SZONE) and not c:IsPreviousLocation(LOCATION_SZONE) and c:IsSetCard(SET_CRYSTAL_BEAST) and c:IsFaceup()
		and c:IsOriginalType(TYPE_MONSTER)
end
--② "보옥수"가 마/함 존에 놓일 때 카운터 추가
function s.ctcon1(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(s.ctfilter,1,nil) then return end
	if Duel.GetCurrentChain()>0 then
		e:GetHandler():RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD|RESET_CHAIN,0,1)
		return false
	end
	return true
end
function s.ctcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetFlagEffect(id)>0 then
		c:ResetFlagEffect(id)
		return true
	else
		return false
	end
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():AddCounter(0x6,1)
end

--③ 젬 카운터 7개 이상 → 덱으로 되돌릴 수 없음
function s.indcon(e)
	return e:GetHandler():GetCounter(0x6)>=7
end

--④ 상대 패 발동 효과에 체인하여 발동
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and re:IsHasType(EFFECT_TYPE_ACTIVATE+EFFECT_TYPE_QUICK_O+EFFECT_TYPE_QUICK_F+EFFECT_TYPE_IGNITION)
		and re:GetHandler():IsLocation(LOCATION_HAND) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x6,4,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x6,4,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end
