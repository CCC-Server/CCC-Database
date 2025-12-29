--F로그라이크 헤드 크러셔
local s,id=GetID()
function c128220110.initial_effect(c)
local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ANNOUNCE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetCondition(s.pubcon)
    e1:SetOperation(s.pubop)
    c:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)
	local e3=Fusion.CreateSummonEff({
		handler=c,
		fusfilter=aux.FilterBoolFunction(Card.IsRace,RACE_ZOMBIE),
		matfilter=Fusion.OnFieldMat(Card.IsAbleToGrave),
		extrafil=s.fextra,
		stage2=s.stage2
	})
	e3:SetCountLimit(1,id)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_HAND)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end
function s.pubcon(e,tp,eg,ep,ev,re,r,rp)
    return not (bit.band(r,REASON_DRAW)==REASON_DRAW)
end
function s.pubop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_PUBLIC)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
    c:RegisterFlagEffect(id, RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END, 0, 1)
end
function s.handcon(e)
    return e:GetHandler():GetFlagEffect(id)>0
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