local s,id=GetID()
function s.initial_effect(c)
	-----------------------------------------------------------
	-- 어드밴스 소환: 가제트 1장 릴리스
	-----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCondition(s.sumcon)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)

	-----------------------------------------------------------
	-- 소환 성공 시 효과 부여
	-----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetOperation(s.regop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------------
-- 어드밴스 소환 조건
-----------------------------------------------------------
function s.gadgetfilter(c)
	return c:IsSetCard(0x51) and c:IsReleasable()
end
function s.sumcon(e,c,minc)
	if c==nil then return true end
	if minc>1 then return false end
	local tributes=Duel.GetTributeGroup(c)
	return tributes:IsExists(s.gadgetfilter,1,nil)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,1,1,s.gadgetfilter)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
	local rc=g:GetFirst()

	-- 릴리스한 카드의 속성과 코드를 저장
	local attr=rc:GetAttribute()
	local code=rc:GetCode()

	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,attr)
	c:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD,0,1,code)
end

-----------------------------------------------------------
-- 소환 성공 시 릴리스 대상에 따라 효과 부여
-----------------------------------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c then return end

	local attr=c:GetFlagEffectLabel(id)
	local code=c:GetFlagEffectLabel(id+100)
	if not attr or not code then return end

	-----------------------------------------------------------
	-- EARTH: 레벨 8 이상 가제트 서치
	-----------------------------------------------------------
	if bit.band(attr,ATTRIBUTE_EARTH)~=0 and s.is_gadget_code(code) then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		e1:SetType(EFFECT_TYPE_IGNITION)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCountLimit(1,{id,1})
		e1:SetTarget(s.thtg)
		e1:SetOperation(s.thop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end

	-----------------------------------------------------------
	-- LIGHT: 상대 몬스터 효과 무효 및 파괴
	-----------------------------------------------------------
	if bit.band(attr,ATTRIBUTE_LIGHT)~=0 and s.is_gadget_code(code) then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,2))
		e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
		e2:SetCode(EVENT_CHAINING)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCountLimit(1,{id,2})
		e2:SetCondition(s.negcon)
		e2:SetCost(s.negcost)
		e2:SetTarget(s.negtg)
		e2:SetOperation(s.negop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	-----------------------------------------------------------
	-- Fortress 지속 함정 릴리스 → 효과 대상 불가
	-----------------------------------------------------------
	local fortress_codes={3955608,42237854,128770412,128770413}
	for _,fc in ipairs(fortress_codes) do
		if code==fc then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
			e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
			e3:SetRange(LOCATION_MZONE)
			e3:SetValue(aux.tgoval)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e3)
			break
		end
	end
end

-----------------------------------------------------------
-- EARTH: 덱에서 레벨 8 이상 가제트 서치
-----------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x51) and c:IsLevelAbove(8) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-----------------------------------------------------------
-- LIGHT: 상대 몬스터 효과 무효 + 파괴
-----------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainDisablable(ev)
end
function s.costfilter1(c)
	return c:IsSetCard(0x51) and c:IsAbleToDeckAsCost()
end
function s.costfilter2(c)
	return c:IsDestructable()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.IsExistingMatchingCard(s.costfilter1,tp,LOCATION_GRAVE,0,1,nil)
	local g2=Duel.IsExistingMatchingCard(s.costfilter2,tp,LOCATION_ONFIELD,0,1,nil)
	if chk==0 then return g1 or g2 end

	local opt
	if g1 and g2 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif g1 then opt=0 else opt=1 end

	if opt==0 then
		local tg=Duel.SelectMatchingCard(tp,s.costfilter1,tp,LOCATION_GRAVE,0,1,1,nil)
		Duel.SendtoDeck(tg,nil,SEQ_DECKBOTTOM,REASON_COST)
	else
		local tg=Duel.SelectMatchingCard(tp,s.costfilter2,tp,LOCATION_ONFIELD,0,1,1,nil)
		Duel.Destroy(tg,REASON_COST)
	end
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-----------------------------------------------------------
-- 코드가 가제트 몬스터인지 확인
-----------------------------------------------------------
function s.is_gadget_code(code)
	local gadget_list = {
		45496366, -- 그린 가제트
		13839120, -- 레드 가제트
		41685633, -- 옐로우 가제트
		60410769, -- 골드 가제트
		96746083, -- 실버 가제트
		-- 여기에 가제트 몬스터 추가 가능
	}
	for _,v in ipairs(gadget_list) do
		if code==v then return true end
	end
	return false
end


