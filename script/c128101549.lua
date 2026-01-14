-- 데드웨어 커럽티드 코어
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 드로우 이외의 방법으로 패에 넣어졌을 경우 발동 (강제 효과)
	-- 원래 주인의 필드에 특수 소환한다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- ②: 일반 소환 / 특수 소환했을 경우 발동 (선택 효과)
	-- 필드의 몬스터 1장을 대상으로 하고 자신의 패에 넣는다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg2)
	e2:SetOperation(s.thop2)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	-- ③: 묘지에 존재하고, 상대가 몬스터를 특수 소환했을 경우 발동 (선택 효과)
	-- 이 카드를 상대의 패에 넣는다.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thcon3)
	e3:SetTarget(s.thtg3)
	e3:SetOperation(s.thop3)
	c:RegisterEffect(e3)
end

-- ① 효과 로직: 드로우 이외로 패 추가 시 원래 주인 필드에 특소
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	-- REASON_DRAW가 아닐 때 (서치, 회수 등)
	return not (r & REASON_DRAW == REASON_DRAW)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		local owner=c:GetOwner()
		-- 원래 주인의 필드에 공간이 있는지 확인 후 특수 소환
		if Duel.GetLocationCount(owner,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(c,0,tp,owner,false,false,POS_FACEUP)
		end
	end
end

-- ② 효과 로직: 소환 시 필드 몬스터 바운스
function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		-- 대상을 컨트롤러(tp)의 패로 넣음 (상대 카드는 주인 패로 감)
		Duel.SendtoHand(tc,tp,REASON_EFFECT)
	end
end

-- ③ 효과 로직: 상대 특소 시 묘지에서 상대 패로 침투
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	-- 소환 플레이어가 상대(1-tp)인 몬스터가 존재하는지 확인
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.thtg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- 별의 금화(Gold Moon Coin) 로직 참고: 상대(1-tp)의 패로 보냄
		if Duel.SendtoHand(c,1-tp,REASON_EFFECT)>0 then
			Duel.ConfirmCards(tp,c) -- 자신도 확인
			Duel.ShuffleHand(1-tp) -- 상대 패 섞기
		end
	end
end