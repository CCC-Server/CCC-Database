--퍼스널 매직 서클 오브 아밀리아
local s,id=GetID()
function s.initial_effect(c)
	-- 발동
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	
	-- ①: 자신 메인 페이즈에 패/덱에서 "아밀리아" 지속 함정 앞면 표시로 놓음
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	-- ②: 자신 필드의 환상마족 몬스터는 각각 1턴에 1번만 전투/효과로 파괴되지 않는다 (시프르 로직)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_ILLUSION))
	e3:SetValue(s.indct)
	c:RegisterEffect(e3)
	
	-- ③: 엔드 페이즈에 묘지의 환상마족 1장 + "아밀리아" 마/함 1장을 덱으로 되돌리고 1장 드로우
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetTarget(s.tdtg)
	e4:SetOperation(s.tdop)
	c:RegisterEffect(e4)
end

-- [① 지속 함정 놓기 필터]
function s.plfilter(c,tp)
	return c:IsSetCard(0xfa5) and c:IsContinuousTrap() and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

-- [① 타겟 지정]
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,tp) end
end

-- [① 효과 처리]
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

-- [② 1턴에 1번 파괴 내성 카운트 체크]
function s.indct(e,re,r,rp)
	if (r&(REASON_BATTLE|REASON_EFFECT))~=0 then
		return 1
	else 
		return 0 
	end
end

-- [③ 덱 바운스 필터 1: 환상마족 몬스터]
function s.td1filter(c)
	return c:IsMonster() and c:IsRace(RACE_ILLUSION) and c:IsAbleToDeck()
end

-- [③ 덱 바운스 필터 2: "아밀리아" 마법/함정]
function s.td2filter(c)
	return c:IsSpellTrap() and c:IsSetCard(0xfa5) and c:IsAbleToDeck()
end

-- [③ 타겟 지정]
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return 
		Duel.IsExistingMatchingCard(s.td1filter,tp,LOCATION_GRAVE,0,1,nil) and Duel.IsExistingMatchingCard(s.td2filter,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

-- [③ 효과 처리]
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.IsExistingMatchingCard(s.td1filter,tp,LOCATION_GRAVE,0,1,nil) and Duel.IsExistingMatchingCard(s.td2filter,tp,LOCATION_GRAVE,0,1,nil) then
		
		-- 각각 1장씩 깔끔하게 선택하도록 처리
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g1=Duel.SelectMatchingCard(tp,s.td1filter,tp,LOCATION_GRAVE,0,1,1,nil)
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g2=Duel.SelectMatchingCard(tp,s.td2filter,tp,LOCATION_GRAVE,0,1,1,nil)
		
		g1:Merge(g2)
		if #g1==2 and Duel.SendtoDeck(g1,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
			local og=Duel.GetOperatedGroup()
			if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
				Duel.ShuffleDeck(tp)
				Duel.Draw(tp,1,REASON_EFFECT)
			end
		end
	end
end