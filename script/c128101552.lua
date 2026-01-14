-- 데드웨어 샌드박스 격리
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 몬스터명 선언, 상대는 자신의 패/묘지에서 그 몬스터를 내 필드에 특소. 그 후 필드의 카드 1장 파괴 가능.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	c:RegisterEffect(e1)

	-- ②: 드로우 이외로 패에 넣었을 경우, 묘지의 이 카드를 제외하고 3장 중 1장 서치.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon2)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg2)
	e2:SetOperation(s.thop2)
	c:RegisterEffect(e2)
end

-- ① 효과 로직
function s.spfilter1(c,code,e,tp)
	-- 상대(1-tp)의 카드여야 하며, 자신(tp)의 필드에 특수 소환 가능해야 함
	return c:IsCode(code) and c:IsCanBeSpecialSummoned(e,0,1-tp,false,false,POS_FACEUP,tp)
end
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	-- 몬스터 카드만 선언 가능하도록 설정
	local ac=Duel.AnnounceCard(tp,TYPE_MONSTER)
	e:SetLabel(ac)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	local ac=e:GetLabel()
	-- 상대(1-tp)의 패/묘지에서 선언한 몬스터를 필터링
	local g=Duel.GetMatchingGroup(s.spfilter1,tp,0,LOCATION_HAND+LOCATION_GRAVE,nil,ac,e,tp)
	
	-- 내 필드에 소환할 공간이 있고 상대에게 해당 카드가 있다면
	if #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		-- 상대(1-tp)가 직접 고르게 함
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
		local sg=g:Select(1-tp,1,1,nil)
		if #sg>0 then
			-- 상대(1-tp)가 소환 주체가 되어 자신(tp)의 필드에 특수 소환
			if Duel.SpecialSummon(sg,0,1-tp,tp,false,false,POS_FACEUP)>0 then
				-- 그 후, 필드의 카드 1장을 파괴할 수 있다.
				local dg=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
				if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					Duel.BreakEffect()
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
					local des=dg:Select(tp,1,1,nil)
					Duel.HintSelection(des)
					Duel.Destroy(des,REASON_EFFECT)
				end
			end
		end
	end
end

-- ② 효과 로직
function s.thfilter2(c)
	return c:IsSetCard(0xc55) and not c:IsCode(id) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToDeck()
end
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	-- 드로우 이외의 방법으로 패에 넣어졌을 때 (범용 조건)
	return eg:IsExists(function(c) return not c:IsReason(REASON_DRAW) end,1,nil)
end
function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.thfilter2,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		-- 서로 다른 이름의 카드가 3장 이상 필요
		return g:GetClassCount(Card.GetCode)>=3
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.thfilter2,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	if g:GetClassCount(Card.GetCode)<3 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	-- 서로 다른 이름의 카드 3장을 선택
	local sg=aux.SelectUnselectGroup(g,e,tp,3,3,aux.dncheck,1,tp,HINTMSG_TODECK)
	
	if #sg==3 then
		Duel.ConfirmCards(1-tp,sg)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local th=sg:Select(tp,1,1,nil)
		local tc=th:GetFirst()
		
		-- 선택한 1장은 패로, 나머지는 덱으로
		sg:RemoveCard(tc)
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
			Duel.ShuffleHand(tp)
			Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		else
			Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end