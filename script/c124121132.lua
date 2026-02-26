-- 환홍허신 안틸라
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 함정 카드를 포함하는 묘지/제외 상태의 카드 2장을 덱 바운스, 그 후 1장 드로우
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
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

-- [① 그룹 검증 함수 (rescon)] 선택한 그룹(sg) 안에 함정 카드가 1장 이상 포함되어 있는가?
function s.rescon(sg,e,tp,mg)
	return sg:IsExists(Card.IsType,1,nil,TYPE_TRAP)
end

-- [① 타겟 지정 (스컬 데몬 로직 적용)]
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end -- 다중 타겟팅이므로 기본 chkc 무시
	
	-- 대상 범위: 덱으로 되돌릴 수 있는, 서로의 묘지 및 제외 존의 카드
	local g=Duel.GetMatchingGroup(function(c,e) return c:IsAbleToDeck() and c:IsCanBeEffectTarget(e) end,tp,LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE|LOCATION_REMOVED,nil,e)
	
	if chk==0 then 
		return Duel.IsPlayerCanDraw(tp,1) 
			and #g>=2 
			-- 선택 가능한 그룹에서 "함정을 포함하는 2장" 조합이 존재하는지 엔진이 미리 시뮬레이션
			and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) 
	end
	
	-- 플레이어에게 2장을 동시에 고르게 하되, 함정이 안 들어가면 선택 완료가 안 되게 통제
	local tg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_TODECK)
	Duel.SetTargetCard(tg)
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

-- [① 효과 처리 (탐욕의 항아리 로직 유지)]
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	if not tg or tg:FilterCount(Card.IsRelateToEffect,nil,e)~=2 then return end
	
	-- 1. 덱 맨 위로 되돌리기
	Duel.SendtoDeck(tg,nil,SEQ_DECKTOP,REASON_EFFECT)
	local og=Duel.GetOperatedGroup()
	
	-- 2. 되돌아간 덱이 있다면 셔플
	if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
		if og:IsExists(Card.IsControler,1,nil,tp) then Duel.ShuffleDeck(tp) end
		if og:IsExists(Card.IsControler,1,nil,1-tp) then Duel.ShuffleDeck(1-tp) end
	end
	
	-- 3. 2장이 모두 무사히 덱/엑스트라 덱에 들어갔다면 드로우
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

-- [② 조건] 제외되었을 경우는 기존과 동일하게 무조건 발동 가능
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