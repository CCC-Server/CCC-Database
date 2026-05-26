-- 환홍허신 안틸라
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 프리 체인 발동 (묘지 / 제외 상태의 카드 2장을 대상으로 발동)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN) -- 프리 체인 방식으로 롤백
	e1:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
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

-- [① 그룹 검증 함수] 선택한 그룹(sg) 안에 "앞면 표시의 함정 카드"가 최소 1장 이상 포함되어 있는가?
function s.rescon(sg,e,tp,mg)
	return sg:IsExists(function(c) return c:IsFaceup() and c:IsType(TYPE_TRAP) end,1,nil)
end

-- [① 타겟 지정] 앞면 / 뒷면 상관없이 묘지 및 제외 존 카드 지정 가능
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	
	-- 묘지와 제외 존의 덱 바운스 가능한 모든 카드를 수집 (앞면/뒷면 무관)
	local g=Duel.GetMatchingGroup(function(c,e) return c:IsAbleToDeck() and c:IsCanBeEffectTarget(e) end,tp,LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE|LOCATION_REMOVED,nil,e)
	
	if chk==0 then 
		return Duel.IsPlayerCanDiscardDeck(tp,1)
			and Duel.IsPlayerCanDraw(tp,1) 
			and #g>=2 
			and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) 
	end
	
	-- 앞면 표시 함정이 반드시 1장 포함되도록 플레이어가 2장 선택
	local tg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_TODECK)
	Duel.SetTargetCard(tg)
	
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

-- [① 효과 처리] 덱 탑 덤핑 -> 대상 카드 덱 바운스 -> 드로우
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 자신의 덱 맨 위의 카드를 묘지로 보낸다
	if Duel.DiscardDeck(tp,1,REASON_EFFECT)<=0 then return end
	
	local tg=Duel.GetTargetCards(e)
	if not tg or tg:FilterCount(Card.IsRelateToEffect,nil,e)~=2 then return end
	
	Duel.BreakEffect()
	-- 2. 대상 카드를 덱으로 되돌리기
	Duel.SendtoDeck(tg,nil,SEQ_DECKTOP,REASON_EFFECT)
	local og=Duel.GetOperatedGroup()
	
	-- 되돌아간 메인 덱 셔플 처리
	if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
		if og:IsExists(Card.IsControler,1,nil,tp) then Duel.ShuffleDeck(tp) end
		if og:IsExists(Card.IsControler,1,nil,1-tp) then Duel.ShuffleDeck(1-tp) end
	end
	
	-- 3. 2장이 메인/엑스트라 덱으로 무사히 복귀했다면 1장 드로우
	local ct=og:FilterCount(Card.IsLocation,nil,LOCATION_DECK|LOCATION_EXTRA)
	if ct==2 then
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

-- [② 조건] "자신의 효과"로 묘지로 보내졌을 경우 (rp==tp)
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