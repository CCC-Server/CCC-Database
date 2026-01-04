-- 바리언즈 오버 콜링
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 발동 시 처리 (기망황 -바리언-을 필드 존에 놓음)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- ②: "No.73" 기재 카드 서치/샐비지
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	-- ③: 마법 효과 무효화 (체인 블록을 만들지 않는 지속 효과)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.discon)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
end
s.listed_names={30761649, 36076683} -- 기망황 -바리언-, No.73 격룡신 어비스 스플래시
s.listed_series={SET_BARIANS}

-- [효과 ① 관련 함수]
function s.pzfilter(c)
	return c:IsCode(30761649) and not c:IsForbidden()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.pzfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 then
		local tc=g:GetFirst()
		-- 몬스터를 필드 존에 놓는 특수 처리
		if Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true) then
			-- 게임 규칙상 필드 존의 카드는 필드 마법이어야 하므로 타입을 부여 (안전장치)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
			e1:SetValue(TYPE_SPELL+TYPE_FIELD)
			tc:RegisterEffect(e1)
			
			Duel.RaiseEvent(tc,EVENT_MOVE,e,REASON_EFFECT,tp,tp,0)
		end
	end
end

-- [효과 ② 관련 함수]
function s.thfilter(c)
	return c:ListsCode(36076683) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- [효과 ③ 관련 함수]
function s.xyzfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_WATER) and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT)
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 발동한 마법 카드 효과 처리 시
	return rp==1-tp and re:IsActiveType(TYPE_SPELL) and Duel.IsChainDisablable(ev)
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_CARD,0,id)
		local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
		if #g>0 then
			local tc=g:GetFirst()
			if tc:RemoveOverlayCard(tp,1,1,REASON_EFFECT) then
				Duel.HintSelection(g)
				Duel.NegateEffect(ev)
			end
		end
	end
end