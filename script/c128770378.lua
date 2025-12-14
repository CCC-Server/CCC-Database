local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드는 룰상 "라바르"로도 취급한다
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x39)
	c:RegisterEffect(e0)

	-- ① 이 카드의 발동 효과 (1장만 발동 가능)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 🔹공통 필터: 라바르 몬스터
function s.lavalfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster()
end

-- 🔹덱에서 서치용 필터
function s.thfilter(c)
	return s.lavalfilter(c) and c:IsAbleToHand()
end

-- 🔹묘지에서 특수 소환 필터
function s.spfilter(c,e,tp)
	return s.lavalfilter(c) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- 🔹① 효과 선택 (서치 or 특소)
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	if chk==0 then return b1 or b2 end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1)) -- "효과를 선택하세요"
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3)) -- ●서치 / ●특소
	elseif b1 then
		Duel.SelectOption(tp,aux.Stringid(id,2))
		op=0
	else
		Duel.SelectOption(tp,aux.Stringid(id,3))
		op=1
	end
	e:SetLabel(op)
	if op==0 then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	else
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	end
end

-- 🔹① 처리 (선택한 효과 실행)
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		-- 덱에서 라바르 몬스터 1장 패에
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	else
		-- 묘지에서 라바르 몬스터 1장 특수 소환
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
