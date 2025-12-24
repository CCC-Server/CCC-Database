--F로그라이크 헤드 크러셔
local s,id=GetID()
function c128220110.initial_effect(c)
	local e1=Fusion.CreateSummonEff({
		handler=c,
		fusfilter=aux.FilterBoolFunction(Card.IsRace,RACE_ZOMBIE),
		matfilter=Fusion.OnFieldMat(Card.IsAbleToGrave),
		extrafil=s.fextra,
		stage2=s.stage2
	})
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
	
	-- 패 발동 조건: 자신 필드에 "F로그라이크" 카드가 존재할 경우
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	-- ②: 묘지 회수 (드로우 이외의 방법으로 패에 넣어졌을 경우)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
function s.handcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xc25),e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_DECK,0,nil,0xc25),s.fcheck
end
function s.fcheck(tp,sg,fc)
	return sg:FilterCount(Card.IsLocation,nil,LOCATION_DECK)<=1
end
function s.stage2(e,tc,tp,sg,chk)
	if chk==1 and not tc:IsSetCard(0xc25) and sg:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
		return false 
	end
end
function s.cfilter(c,tp)
	return c:IsControler(tp) and not c:IsReason(REASON_DRAW)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end