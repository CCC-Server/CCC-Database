local s,id=GetID()
function s.initial_effect(c)
	-- ①: 패에서 특수 소환 (1턴 1번)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ②: 엑스트라 덱 특수 소환 시, 묘지의 네메시스 아티팩트 회수 (1턴 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- 카드군 필터 (네메시스 아티팩트 몬스터)
function s.nemesis_filter(c)
	return c:IsFaceup() and c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
end

-- ① 특수 소환 조건: 필드 또는 마법/함정존에 네메시스 아티팩트 몬스터가 존재할 경우
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.nemesis_filter,tp,LOCATION_ONFIELD,0,1,nil)
end

-- ② 발동 조건: 엑스트라 덱에서 네메시스 아티팩트 몬스터가 특수 소환된 경우
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsSetCard(0x764) and c:IsSummonPlayer(tp) and c:IsSummonLocation(LOCATION_EXTRA)
	end,1,nil)
end

-- ② 대상 필터: 묘지의 네메시스 아티팩트 몬스터
function s.thfilter(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

-- ② 타겟 지정
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

-- ② 작동: 패로 되돌림
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
