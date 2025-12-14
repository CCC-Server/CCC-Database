local s,id=GetID()
function s.initial_effect(c)
	-- ① 패에서 특수 소환 (네메시스 퍼펫 존재 시)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ② 덱에서 네메시스 퍼펫 일반 몬스터 1장 서치
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- ③ 소재로 있을 때 아군 네메시스 퍼펫 몬스터 공격력 +500
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_XMATERIAL)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetCondition(s.atkcon)
	e3:SetValue(500)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.atktg)
	c:RegisterEffect(e3)
end

------------------------------------------------
-- ① 특수 소환 조건
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

------------------------------------------------
-- ② 서치 효과
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763) and c:IsType(TYPE_XYZ)
end
function s.thfilter(c)
	return c:IsSetCard(0x763) and c:IsType(TYPE_NORMAL) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
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

------------------------------------------------
-- ③ 공격력 상승 조건 및 대상
function s.atkcon(e)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_OVERLAY) and c:GetOverlayTarget():IsFaceup()
end
function s.atktg(e,c)
	return c:IsSetCard(0x763)
end
