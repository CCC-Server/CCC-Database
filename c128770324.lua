local s,id=GetID()
function s.initial_effect(c)
	-- 융합 소환 조건: "네메시스 아티팩트" 몬스터 2장
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.ffilter,2)

	----------------------------------------------------------------
	-- ①: 융합 소환 성공 시 서치
	----------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	----------------------------------------------------------------
	-- ②: 묘지의 융합 몬스터를 장착
	----------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	----------------------------------------------------------------
	-- ③: 이 카드가 융합 소재로 묘지로 보내졌을 때, 장착되어 있던 융합몬스터 특수 소환
	----------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

----------------------------------------------------------
-- 융합 재료 필터
----------------------------------------------------------
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x764)
end

----------------------------------------------------------
-- ①: 융합 소환 성공 시 서치
----------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.thfilter(c)
	return c:IsSetCard(0x764) and c:IsAbleToHand()
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

----------------------------------------------------------
-- ②: 묘지의 융합 몬스터를 장착
----------------------------------------------------------
function s.eqfilter(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_FUSION) and c:IsLevelBelow(8)
		and not c:IsCode(id) and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,3,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,#g,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end
	for tc in aux.Next(g) do
		if ft<=0 then break end
		if Duel.Equip(tp,tc,c,false) then
			-- 장착 제한
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(function(e,c) return c==e:GetOwner() end)
			tc:RegisterEffect(e1)
			ft=ft-1
		end
	end
end

----------------------------------------------------------
-- ③: 융합 소재로 묘지로 갔을 때, 장착된 몬스터 특수 소환
----------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_MATERIAL) and c:GetReasonCard():IsType(TYPE_FUSION)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x764) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local eqg=c:GetEquipGroup():Filter(s.spfilter,nil,e,tp)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>=#eqg and #eqg>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,eqg,#eqg,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local eqg=c:GetEquipGroup():Filter(s.spfilter,nil,e,tp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 or #eqg==0 then return end
	for tc in aux.Next(eqg) do
		if ft<=0 then break end
		Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP)
		ft=ft-1
	end
	Duel.SpecialSummonComplete()
end
