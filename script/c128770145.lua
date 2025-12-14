--카드명 : Highland Continuous Magic (예시)
local s,id=GetID()
function s.initial_effect(c)
	-- 카드명 1턴 1장 발동 제한
	-- 지속 마법 패에서 발동 가능 (드로우 X)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- 카드명 1턴 1장 발동
	c:RegisterEffect(e1)

	-- ① 필드에서 메인 페이즈 발동: 패 하이랜드 1장 덱 → 드로우 1장
	local e1f=Effect.CreateEffect(c)
	e1f:SetDescription(aux.Stringid(id,0))
	e1f:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e1f:SetType(EFFECT_TYPE_IGNITION)
	e1f:SetRange(LOCATION_SZONE)
	e1f:SetCountLimit(1,id+100)
	e1f:SetCondition(s.drcon)
	e1f:SetTarget(s.drtg)
	e1f:SetOperation(s.drop)
	c:RegisterEffect(e1f)

	-- ② 하이랜드 몬스터 엑스트라 덱 특수 소환 시 발동
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id+200)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- ① 조건: 메인 페이즈
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

-- ① 패에서 하이랜드 카드 1장 선택
function s.tdfilter(c)
	return c:IsSetCard(0x755) and c:IsAbleToDeck()
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_HAND,0,1,1,nil)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

-- ② 조건: 하이랜드 몬스터가 엑스트라 덱에서 특수 소환
function s.cfilter(c,tp)
	return c:IsSetCard(0x755) and c:IsSummonLocation(LOCATION_EXTRA) and c:GetSummonPlayer()==tp
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

-- ② 상대 필드 카드 1장 선택
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end



