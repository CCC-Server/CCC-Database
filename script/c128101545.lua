-- 데드웨어 백도어 엑세서
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 드로우 이외의 방법으로 패에 넣어졌을 경우 발동 (강제 특수 소환)
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

	-- ②: 묘지로 보내졌을 경우 발동 (묘지의 '데드웨어'를 상대 필드에 특소)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)

	-- ③: 드로우 이외의 방법으로 몬스터가 패에 넣어졌을 경우 발동 (원래 주인이 묘지 회수)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thcon3)
	e3:SetTarget(s.thtg3)
	e3:SetOperation(s.thop3)
	c:RegisterEffect(e3)
end

-- ① 효과 로직
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	-- REASON_DRAW가 포함되지 않은 경우 (드로우 이외)
	return not (r & REASON_DRAW == REASON_DRAW)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- 강제 효과
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ② 효과 로직
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0xc55) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter2(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter2,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,1-tp,false,false,POS_FACEUP)
	end
end

-- ③ 효과 로직
function s.thfilter3(c)
	return c:IsType(TYPE_MONSTER) and not (c:GetReason() & REASON_DRAW == REASON_DRAW)
end
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.thfilter3,1,nil)
end
function s.thtg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local owner=e:GetHandler():GetOwner()
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,owner,LOCATION_GRAVE)
end
function s.thop3(e,tp,eg,ep,ev,re,r,rp)
	local owner=e:GetHandler():GetOwner() -- 원래의 주인
	Duel.Hint(HINT_SELECTMSG,owner,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(owner,Card.IsMonster,owner,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-owner,g)
	end
end