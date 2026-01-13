--JJ-스타더스트 크루세이더즈
local s,id=GetID()
function c128220132.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end
function s.splimit(e,c,sump,sumtyp,sumpos,targetp,se)
	return c:IsType(TYPE_EFFECT) and not c:IsCode(128220125)
end
function s.thfilter(c)
	return c:IsSetCard(0xc26) and c:IsType(TYPE_MONSTER) 
		and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup())) 
		and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_EXTRA)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.drfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc26)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.drfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,ct+1) end
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, ct+1, tp, 0)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.drfilter,tp,LOCATION_MZONE,0,nil)
	-- 1. 드로우 실행
	if Duel.Draw(tp,ct+1,REASON_EFFECT)==0 then return end
	
	Duel.ShuffleHand(tp)
	Duel.BreakEffect()
	
	-- 2. 되돌릴 장수 결정 (ct장)
	-- 만약 드로우 후 패가 ct장보다 적을 상황을 대비해 안전장치 추가
	local hand_ct=Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
	local select_ct=math.min(ct,hand_ct)
	
	if select_ct>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		-- 3. Card.IsAbleToDeck이 패에서 간혹 안 먹히는 경우가 있으므로 필터 없이 선택
		local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_HAND,0,select_ct,select_ct,nil)
		if #g>0 then
			-- 4. 덱 아래로 보낼 때는 6번째 인자(셔플)를 false로 설정하는 것이 안정적입니다.
			-- 인자 순서: 그룹, 컨트롤러(nil), 위치, 이유, 대상플레이어, 셔플여부
			Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_EFFECT,tp,false)
			
			-- 5. 덱 아래로 보냈음을 명시적으로 확인 (일부 엔진용)
			local og=Duel.GetOperatedGroup()
			local ct2=og:FilterCount(Card.IsLocation,nil,LOCATION_DECK)
			if ct2>0 then
				-- 덱 아래로 보낸 카드들은 셔플하지 않음
				Duel.SortDecktop(tp,tp,ct2)
				for i=1,ct2 do
					local mg=Duel.GetDecktopGroup(tp,1)
					Duel.MoveSequence(mg:GetFirst(),SEQ_DECKBOTTOM)
				end
			end
		end
	end
end