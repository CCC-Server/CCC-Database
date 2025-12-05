--Over Limit - Infinity Circuit
local s,id=GetID()
function s.initial_effect(c)
	-- 카드명 턴당 1번만 발동 가능
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- "You can only activate 1 card with this card's name per turn."
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	
	-- Limiter Removal 발동에 반응해서 배틀 페이즈 동안 상대 효과 발동 봉인
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id+1) -- 이 효과는 턴당 1번
	e2:SetCondition(s.lrcon)
	e2:SetOperation(s.lrop)
	c:RegisterEffect(e2)
	
	-- "Over Limit" 몬스터 서치
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+2) -- 이 효과는 턴당 1번
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

-- 참고용: 리미터 해제 / 카드군 등록
-- Limiter Removal의 실제 카드 번호
-- OCG 기준: 23171610
s.listed_names={23171610}
-- "Over Limit" 카드군 코드
s.listed_series={0xc48}

-- ①: When this card is activated:
-- You can send 1 "Limiter Removal" from your Deck to the GY.
-- If "Limiter Removal" is in your GY, you can add it to your hand instead.

-- 덱에서 GY로 보낼 Limiter Removal
function s.lrdeckfilter(c)
	return c:IsCode(23171610) and c:IsAbleToGrave()
end
-- 묘지에서 서치할 Limiter Removal
function s.lrgyfilter(c)
	return c:IsCode(23171610) and c:IsAbleToHand()
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.lrdeckfilter,tp,LOCATION_DECK,0,1,nil)
			or Duel.IsExistingMatchingCard(s.lrgyfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	-- 둘 중 하나를 선택할 수 있으므로 둘 다 잠재적인 정보로 올려 둠
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.IsExistingMatchingCard(s.lrdeckfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.lrgyfilter,tp,LOCATION_GRAVE,0,1,nil)
	if not (b1 or b2) then return end
	
	-- 둘 다 가능하면 플레이어가 선택
	local op
	if b1 and b2 then
		-- [0] 덱에서 GY로 / [1] 묘지에서 패로
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then
		op=0
	else
		op=1
	end
	
	if op==0 then
		-- 덱에서 Limiter Removal 1장 GY로
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.lrdeckfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	else
		-- GY에 있는 Limiter Removal 1장 패로
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.lrgyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
				Duel.ConfirmCards(1-tp,g)
			end
		end
	end
end

-- ②: Once per turn, if "Limiter Removal" is activated:
-- You can activate this effect; your opponent cannot activate card effects during the Battle Phase this turn.

function s.lrcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	-- "Limiter Removal"의 발동에 체인되었을 때
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsCode(23171610)
end

function s.lrop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 이 턴의 배틀 페이즈 동안 상대는 카드 효과를 발동할 수 없다
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,5))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetTargetRange(0,1) -- 상대만
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_BATTLE)
	Duel.RegisterEffect(e1,tp)
end

function s.aclimit(e,re,tp)
	-- 배틀 페이즈에서만 봉인
	local ph=Duel.GetCurrentPhase()
	if ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE then
		return true
	end
	return false
end

-- ③: Once per turn: You can add 1 "Over Limit" monster from your Deck to your hand.

function s.thfilter(c)
	return c:IsSetCard(0xc48) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
