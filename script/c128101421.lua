--Horus the Black Flame Dragon Deity - Overlord (가칭)
local s,id=GetID()
local SET_HORUS=0x1003  -- "Horus the Black Flame Dragon" 카드군

function s.initial_effect(c)
	--------------------------------------
	-- (1) 패에서 공개 → 호루스 카드 서치 + 이 카드 덱으로 되돌리기
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- (1) HOPT
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--------------------------------------
	-- (2) 상대는 마법 카드 효과로 특수 소환 불가
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)  -- 상대만
	e2:SetTarget(s.splimit)
	c:RegisterEffect(e2)

	--------------------------------------
	-- (3) 프리체인 범용 퍼미션
	--------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetCountLimit(1,{id,1})-- (3) HOPT
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

--------------------------------------------------
-- (1) 패에서 공개 → 호루스 카드 서치 + 자신 덱으로
--------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_HORUS) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 패에서 이 카드 공개 (연출용)
	if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,c)
		Duel.ShuffleHand(tp)  -- 나머지 패는 섞어줌
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		-- 성공적으로 서치했다면, 이 카드를 덱으로 되돌림
		if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_HAND) then
			Duel.BreakEffect()
			Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

--------------------------------------------------
-- (2) 상대는 마법 카드 효과로 특수 소환 불가
--------------------------------------------------
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	-- se : 소환을 일으킨 효과
	return se and se:IsActiveType(TYPE_SPELL)
end

--------------------------------------------------
-- (3) 프리체인 퍼미션
--	 상대가 카드/효과 발동 시, 자신 필드 카드 1장 묘지로 → 무효 & 파괴
--------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end

function s.cfilter_cost(c,tp)
	return c:IsControler(tp) and c:IsOnField() and c:IsAbleToGraveAsCost()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.cfilter_cost,tp,LOCATION_ONFIELD,0,1,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter_cost,tp,LOCATION_ONFIELD,0,1,1,nil,tp)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=re:GetHandler()
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if rc:IsRelateToEffect(re) and rc:IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		if rc:IsRelateToEffect(re) then
			Duel.Destroy(rc,REASON_EFFECT)
		end
	end
end
