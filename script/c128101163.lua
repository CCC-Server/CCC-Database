--RR-라스트 아센션
local s,id=GetID()
function s.initial_effect(c)
	-- ① 엑시즈 랭크업 (1턴 1회)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_ONFIELD)
	e1:SetCountLimit(1,{id,1})
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.rkcon1)
	e1:SetTarget(s.rktg)
	e1:SetOperation(s.rkop)
	c:RegisterEffect(e1)

	-- 상대 턴에도 발동 가능 (어둠 속성 몬스터만 있을 경우)
	local e1q=e1:Clone()
	e1q:SetType(EFFECT_TYPE_QUICK_O)
	e1q:SetCode(EVENT_FREE_CHAIN)
	e1q:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1q:SetCondition(s.rkcon2)
	c:RegisterEffect(e1q)

	-- ② 묘지에서 회수 (엔드 페이즈)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- ① 조건: 자신 필드에 "RR" 엑시즈 존재
function s.rkfilter(c,e,tp)
	local rk=c:GetRank()
	return c:IsFaceup() and c:IsSetCard(0xba) and c:IsType(TYPE_XYZ)
		and Duel.IsExistingMatchingCard(s.rkfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,rk)
end
function s.rkfilter2(c,e,tp,rc,oldrk)
	local newrk=c:GetRank()
	return c:IsSetCard(0xba) and c:IsType(TYPE_XYZ)
		and (newrk==oldrk+1 or newrk==oldrk+2)
		and rc:IsCanBeXyzMaterial(c,tp)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.rkcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.rkcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() and Duel.IsTurnPlayer(1-tp)
		and not Duel.IsExistingMatchingCard(function(c) return not (c:IsAttribute(ATTRIBUTE_DARK) or not c:IsFaceup()) end,tp,LOCATION_MZONE,0,1,nil)
end
function s.rktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.rkfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.rkfilter,tp,LOCATION_MZONE,0,1,nil,e,tp) and e:GetHandler():IsAbleToGraveAsCost() end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.rkfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end
function s.rkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not Duel.SendtoGrave(c,REASON_COST) then return end
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or tc:IsFacedown() or not tc:IsControler(tp) then return end
	local rk=tc:GetRank()
	local g=Duel.GetMatchingGroup(s.rkfilter2,tp,LOCATION_EXTRA,0,nil,e,tp,tc,rk)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=g:Select(tp,1,1,nil):GetFirst()
	if sc then
		local mg=tc:GetOverlayGroup()
		if #mg>0 then
			Duel.Overlay(tc,mg)
		end
		sc:SetMaterial(Group.FromCards(tc))
		Duel.Overlay(sc,Group.FromCards(tc))
		Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end

-- ② 묘지 회수 조건: 이 턴에 묘지로 간 경우
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_COST+REASON_EFFECT+REASON_RELEASE+REASON_DISCARD)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end
