local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- 융합 소재: 이름이 다른 다이놀피어 몬스터 2장
	Fusion.AddProcMixN(c,true,true,s.matfilter,2)

	-- ① 융합 소환 성공 시: 다이놀피어 함정 회수 or 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	-- ② 함정 효과 복사
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCost(s.copycost)
	e2:SetTarget(s.copytg)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)

	-- ③ 파괴 시 리쿠르트
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- 융합 소재 필터
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x175,fc,sumtype,tp) and not c:IsCode(fc:GetCode())
end

-- ① 융합 소환 성공시
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.setfilter(c)
	return c:IsSetCard(0x175) and c:IsType(TYPE_TRAP) and (c:IsAbleToHand() or c:IsSSetable())
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	local canToHand=tc:IsAbleToHand()
	local canSet=tc:IsSSetable()
	if canToHand and canSet then
		local opt=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4)) -- 0: 패, 1: 세트
		if opt==0 then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		else
			Duel.SSet(tp,tc)
		end
	elseif canToHand then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	elseif canSet then
		Duel.SSet(tp,tc)
	end
end

-- ② 효과 복사
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,Duel.GetLP(tp)//2)
		and Duel.IsExistingMatchingCard(s.cpyfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.PayLPCost(tp,Duel.GetLP(tp)//2)
end
function s.cpyfilter(c)
	return c:IsSetCard(0x175) and c:IsType(TYPE_TRAP) and c:CheckActivateEffect(false,true,false) and c:IsAbleToRemoveAsCost()
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.cpyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	local te=tc:CheckActivateEffect(false,true,true)
	if te then
		Duel.Remove(tc,POS_FACEUP,REASON_COST)
		local tg=te:GetTarget()
		if tg then tg(te,tp,Group.CreateGroup(),tp,0,REASON_EFFECT,rp) end
		local op=te:GetOperation()
		if op then op(te,tp,Group.CreateGroup(),tp,0,REASON_EFFECT,rp) end
	end
end

-- ③ 파괴 시 리쿠르트
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT+REASON_BATTLE)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x175) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
