local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x769),2,99)

	-- E1: Each player can only control 1 face-up monster of each Type
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ADJUST)
	e1:SetRange(LOCATION_MZONE)
	e1:SetOperation(s.typecheck)
	c:RegisterEffect(e1)

	-- E2: On Link Summon → negate opponent cards equal to your monster Type count
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon2)
	e2:SetTarget(s.negtg2)
	e2:SetOperation(s.negop2)
	c:RegisterEffect(e2)

	-- E3: If destroyed by opponent and sent to GY → revive during End Phase
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.revcon)
	e3:SetCost(s.revcost)
	e3:SetOperation(s.revop)
	c:RegisterEffect(e3)
end

-- E1: 타입 중복 제거
function s.typecheck(e,tp,eg,ep,ev,re,r,rp)
	for p=0,1 do
		local g=Duel.GetMatchingGroup(Card.IsFaceup,p,LOCATION_MZONE,0,nil)
		local seen = {}
		local to_send = Group.CreateGroup()
		for tc in aux.Next(g) do
			local r=tc:GetRace()
			if seen[r] then
				to_send:AddCard(tc)
			else
				seen[r]=true
			end
		end
		if #to_send>0 then
			Duel.SendtoGrave(to_send,REASON_RULE)
		end
	end
end

-- E2: 링크 소환 확인
function s.negcon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- E2: 타입 수만큼 상대 카드 무효화
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.count_unique_types(g)
	local seen = {}
	for tc in aux.Next(g) do
		seen[tc:GetRace()] = true
	end
	local count = 0
	for _,_ in pairs(seen) do count = count + 1 end
	return count
end
function s.negtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local count=s.count_unique_types(g)
	if chk==0 then return Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tg=Duel.SelectMatchingCard(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,count,nil)
	Duel.SetTargetCard(tg)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,tg,#tg,0,0)
end
function s.negop2(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	for tc in aux.Next(tg) do
		if tc:IsFaceup() and tc:IsRelateToEffect(e) then
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
		end
	end
end

-- E3: 상대 효과로 파괴되어 GY
function s.revcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp==1-tp and c:IsReason(REASON_EFFECT) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.revfilter(c)
	return c:IsSetCard(0x769) and c:IsAbleToRemoveAsCost()
end
function s.revcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.revfilter,tp,LOCATION_GRAVE,0,1,nil) end
	local g=Duel.SelectMatchingCard(tp,s.revfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetLabelObject(c)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
