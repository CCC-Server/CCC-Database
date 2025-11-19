--하피 속공마법 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--Activate: choose 1 of 3 effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) -- 효과 발동 설명
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={SET_HARPIE}
s.listed_names={CARD_HARPIE_LADY,CARD_HARPIE_LADY_SISTERS}

-- 3개 선택지 중 각 효과 1턴 1회
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(-100)
	local b1=not Duel.HasFlagEffect(tp,id)
	local b2=not Duel.HasFlagEffect(tp,id+100)
	local b3=not Duel.HasFlagEffect(tp,id+200)
	if chk==0 then return b1 or b2 or b3 end
end

function s.thfilter(c)
	return c:IsSetCard(SET_HARPIE) and c:IsLevelAbove(6) and c:IsAbleToHand()
end

function s.ssfilter(c,e,tp,code)
	return c:IsSetCard(SET_HARPIE) and not c:IsCode(code)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_EXTRA))
end

function s.harpiemon(c)
	return c:IsFaceup() and (c:IsCode(CARD_HARPIE_LADY) or c:IsCode(CARD_HARPIE_LADY_SISTERS))
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local cost_skip = e:GetLabel() ~= -100
	local b1=not Duel.HasFlagEffect(tp,id)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=not Duel.HasFlagEffect(tp,id+100)
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_HARPIE),tp,LOCATION_MZONE,0,1,nil)
	local b3=not Duel.HasFlagEffect(tp,id+200)
		and Duel.IsExistingMatchingCard(s.harpiemon,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil)
	if chk==0 then e:SetLabel(0) return b1 or b2 or b3 end

	-- ✅ 선택지 텍스트 표시되도록 StringID 사용
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)}, -- 덱에서 하피 레벨6 이상 패에
		{b2,aux.Stringid(id,2)}, -- 하피 대상 → 다른 이름 특소
		{b3,aux.Stringid(id,3)}) -- 하피 레이디/세자매 수 만큼 파괴
	e:SetLabel(op)

	if op==1 then
		e:SetCategory(CATEGORY_TOHAND)
		if not cost_skip then Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1) end
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)

	elseif op==2 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		if not cost_skip then Duel.RegisterFlagEffect(tp,id+100,RESET_PHASE|PHASE_END,0,1) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local g=Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsSetCard,SET_HARPIE),tp,LOCATION_MZONE,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)

	elseif op==3 then
		e:SetCategory(CATEGORY_DESTROY)
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		if not cost_skip then Duel.RegisterFlagEffect(tp,id+200,RESET_PHASE|PHASE_END,0,1) end
		local count=Duel.GetMatchingGroupCount(s.harpiemon,tp,LOCATION_MZONE,0,nil)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,count,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end

	elseif op==2 then
		local tc=Duel.GetFirstTarget()
		if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
		local code=tc:GetCode()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.ssfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp,code)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end

	elseif op==3 then
		local tg=Duel.GetTargetCards(e)
		if #tg>0 then
			Duel.Destroy(tg,REASON_EFFECT)
		end
	end
end
