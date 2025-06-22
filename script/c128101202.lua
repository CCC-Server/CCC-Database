local s,id=GetID()
function s.initial_effect(c)
	Pendulum.AddProcedure(c)

	-- 펜듈럼 효과 ①: 누벨즈 몬스터 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.pcon1)
	e1:SetTarget(s.ptg1)
	e1:SetOperation(s.pop1)
	c:RegisterEffect(e1)

	-- 펜듈럼 효과 ②: 누벨즈 특소 시 자가 특소
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.pcon2)
	e2:SetTarget(s.ptg2)
	e2:SetOperation(s.pop2)
	c:RegisterEffect(e2)

	-- 몬스터 효과 ①: 몬스터 특소 포함 효과 발동 시 패에서 특소
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.mcon1)
	e3:SetTarget(s.mtg1)
	e3:SetOperation(s.mop1)
	c:RegisterEffect(e3)

	-- 몬스터 효과 ②: 소환 성공 시 요리 마함을 코스트로 묘지로 보내고, 효과 복사 실행
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,{id,3})
	e4:SetCost(s.mcost2)
	e4:SetTarget(s.mtg2)
	e4:SetOperation(s.mop2)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e5)

	-- 몬스터 효과 ③: 릴리스되어 엑덱 앞면 → 펜듈럼 존
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,4))
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_MOVE)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCountLimit(1,{id,4})
	e6:SetCondition(s.mcon3)
	e6:SetTarget(s.mtg3)
	e6:SetOperation(s.mop3)
	c:RegisterEffect(e6)
end

------------------------
-- 펜듈럼 효과 처리
------------------------

-- E1: 메인 페이즈
function s.pcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2)
end
function s.thfilter1(c)
	return c:IsSetCard(0x197) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.ptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.pop1(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- E2: 누벨즈 특수 소환 감지
function s.pcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsSetCard(0x197) and c:IsControler(tp) end,1,nil)
end
function s.ptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.pop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

------------------------
-- 몬스터 효과 처리
------------------------

-- E3: 특소 포함 체인 반응 시 패에서 특수 소환
function s.mcon1(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return re:IsActivated() and rc:IsType(TYPE_MONSTER)
		and re:IsHasCategory(CATEGORY_SPECIAL_SUMMON)
end
function s.mtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.mop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- E4: 마법 코스트로 보내고 효과 복사
function s.copfilter2(c)
	return c:IsCode(14283055)
		and c:IsAbleToGraveAsCost()
		and (c:IsNormalSpell() or c:IsQuickPlaySpell())
		and c:CheckActivateEffect(true,true,false)~=nil
end
function s.mcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.copfilter2,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.copfilter2,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if not Duel.SendtoGrave(tc,REASON_COST) then return end
	local te=tc:CheckActivateEffect(true,true,false)
	if te then
		e:SetLabel(te:GetLabel())
		e:SetLabelObject(te:GetLabelObject())
		local tg=te:GetTarget()
		if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
		te:SetLabel(e:GetLabel())
		te:SetLabelObject(e:GetLabelObject())
		e:SetLabelObject(te)
		Duel.ClearOperationInfo(0)
	end
end
function s.mtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end
function s.mop2(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if te then
		e:SetLabel(te:GetLabel())
		e:SetLabelObject(te:GetLabelObject())
		local op=te:GetOperation()
		if op then op(e,tp,eg,ep,ev,re,r,rp) end
	end
end

-- E5: 릴리스되어 엑덱에서 펜듈럼 존으로
function s.mcon3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsLocation(LOCATION_EXTRA)
		and c:IsFaceup() and c:IsReason(REASON_RELEASE)
end
function s.mtg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) end
end
function s.mop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.CheckPendulumZones(tp) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end
