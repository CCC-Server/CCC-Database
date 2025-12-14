local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 절차
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,
		aux.FilterSummonCode,1,99,s.matfilter)
	c:EnableReviveLimit()

	------------------------------------------
	--① 덱에서 "스파클 아르카디아" 마/함 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	------------------------------------------
	--② 속공 리버스 (자신 턴에는 2장까지)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_POSITION)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,2})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetTarget(s.postg)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)
end
s.listed_series={0x760}

--------------------------------------------------
--싱크로 소재 조건
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x760,lc,sumtype,tp) and not c:IsType(TYPE_TUNER,lc,sumtype,tp)
end

--------------------------------------------------
--① 세트 조건
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.setfilter(c)
	return c:IsSetCard(0x760) and (c:IsType(TYPE_SPELL+TYPE_TRAP)) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------------------
--② 리버스 효과
function s.posfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.posfilter(chkc) end
	local ct=Duel.GetTurnPlayer()==tp and 2 or 1
	if chk==0 then return Duel.IsExistingTarget(s.posfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectTarget(tp,s.posfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,#g,0,0)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	for tc in aux.Next(g) do
		if tc:IsRelateToEffect(e) and tc:IsFaceup() then
			Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)
			--표시 형식 변경 불가 효과 부여
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end
