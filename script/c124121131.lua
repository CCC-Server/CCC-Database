-- 환홍허신 포닉스
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 덱 탑 1장 덤핑 후 필드/묘지의 마법/함정 카드 2장까지 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE|TIMING_EQUIP)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- ②: 제외되거나 "자신의 효과"로 묘지에 보내졌을 경우
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_REMOVE)
	e3:SetCondition(s.setcon_rm)
	c:RegisterEffect(e3)
end

-- "환홍" 카드군 코드 (0xfa8)
s.set_phanred=0xfa8

-- [① 제외 대상 필터] (IsSpellTrap 사용 + 제외 가능 여부 확인)
function s.rmfilter(c)
	return c:IsSpellTrap() and c:IsAbleToRemove()
end

-- [① 제외 타겟]
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD|LOCATION_GRAVE) and s.rmfilter(chkc) and chkc~=c end
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,1)
		and Duel.IsExistingTarget(s.rmfilter,tp,LOCATION_ONFIELD|LOCATION_GRAVE,LOCATION_ONFIELD|LOCATION_GRAVE,1,c) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.rmfilter,tp,LOCATION_ONFIELD|LOCATION_GRAVE,LOCATION_ONFIELD|LOCATION_GRAVE,1,2,c)
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

-- [① 제외 효과 처리]
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.DiscardDeck(tp,1,REASON_EFFECT)>0 then
		local tg=Duel.GetTargetCards(e)
		if #tg>0 then
			Duel.Remove(tg,POS_FACEUP,REASON_EFFECT)
		end
	end
end

-- [② 조건] "자신의 효과"로 묘지로 보내졌을 경우로 제한 (rp==tp)
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT) and rp==tp
end

-- [② 조건] 제외되었을 경우는 무조건 발동 가능
function s.setcon_rm(e,tp,eg,ep,ev,re,r,rp)
	return true
end

-- [② 덱 넘기기 타겟]
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=6 end
end

-- [② 환홍 함정 필터]
function s.setfilter(c)
	return c:IsSetCard(s.set_phanred) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

-- [② 덱 넘기기 효과 처리]
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<6 then return end
	
	Duel.ConfirmDecktop(tp,6)
	local g=Duel.GetDecktopGroup(tp,6)
	
	if #g>0 then
		Duel.DisableShuffleCheck()
		local tg=g:Filter(s.setfilter,nil)
		
		if #tg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local tc=tg:Select(tp,1,1,nil):GetFirst()
			if tc and Duel.SSet(tp,tc)>0 then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetDescription(aux.Stringid(id,2))
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
				e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
				e1:SetReset(RESET_EVENT|RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
		
		Duel.ShuffleDeck(tp)
	end
end