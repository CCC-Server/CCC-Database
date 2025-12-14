local s,id=GetID()
function s.initial_effect(c)
	--Activate (발동 시 덱에서 서치)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- 이 카드명의 1턴 1장 발동 제한
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--② 자신의 메인 페이즈 동안 "네메시스 퍼펫" 몬스터는 대상이 되지 않는다
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.tgtg)
	e2:SetCondition(s.tgcon)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	--③ 묘지의 "네메시스 퍼펫" 몬스터 2장 특소 + 엑시즈 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,1}) -- ③ 효과 1턴 1회
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--① 덱에서 "네메시스 퍼펫" 몬스터 1장 서치
function s.thfilter(c)
	return c:IsSetCard(0x763) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

--② 효과: 메인 페이즈 동안만 적용
function s.tgcon(e)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end
function s.tgtg(e,c)
	return c:IsSetCard(0x763) and c:IsType(TYPE_MONSTER)
end

--③ 효과: 묘지의 "네메시스 퍼펫" 2장 특소 + 엑시즈
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x763) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetLevel)==1 -- 같은 레벨 2장
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
	if chk==0 then return aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) end
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_SPSUMMON)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,sg,2,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g~=2 or Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	local c=e:GetHandler()
	Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	if #g==2 and g:GetFirst():GetLevel()==g:GetNext():GetLevel() then
		Duel.BreakEffect()
		Duel.XyzSummon(tp,nil,g)
	end
end
