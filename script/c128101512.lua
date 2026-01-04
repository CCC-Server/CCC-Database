--프레데터 플랜츠 프테라 글로소프
--Predaplant Ptera Glossoph
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 및 소재 설정 ("프레데터 플랜츠" 몬스터 × 2)
	c:EnableReviveLimit()
	Fusion.AddProcFunRep(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_PREDAPLANT),2,true)
	
	--[효과 1] 포식 카운터가 놓인 상대 몬스터 또는 자신 몬스터를 릴리스하고 "프레데터" 마함 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg1)
	e1:SetOperation(s.thop1)
	c:RegisterEffect(e1)
	
	--[효과 2] 효과로 묘지로 보내졌을 경우 "융합/퓨전" 마법 서치
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon2)
	e2:SetTarget(s.thtg2)
	e2:SetOperation(s.thop2)
	c:RegisterEffect(e2)
end

--관련 시리즈 등록
s.listed_series={SET_PREDAPLANT, SET_PREDAP, SET_FUSION}

--효과 1 필터: 자신 필드의 몬스터 또는 포식 카운터가 있는 상대 몬스터
function s.relfilter(c,tp)
	return (c:IsControler(tp) or (c:IsControler(1-tp) and c:GetCounter(COUNTER_PREDATOR)>0))
		and c:IsReleasableByEffect()
end
-- "프레데터(Predap)" 마법/함정 필터
function s.thfilter1(c)
	return c:IsSetCard(SET_PREDAP) and c:IsSpellTrap() and c:IsAbleToHand()
end
function s.thtg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.relfilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.relfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp)
		and Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectTarget(tp,s.relfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Release(tc,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

--효과 2: 효과로 묘지로 보내진 경우 체크
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end
-- "융합(Polymerization)" 또는 "퓨전(Fusion)" 마법 필터
function s.thfilter2(c)
	return c:IsSetCard(SET_FUSION) and c:IsSpell() and c:IsAbleToHand()
end
function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end