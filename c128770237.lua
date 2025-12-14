--스파클 아르카디아 카운터 코어 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 발동 제한 (1턴에 1장)
	c:SetUniqueOnField(1,0,id)

	--① 상대 효과 무효 + 파괴 + 부활
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--② 묘지에서 특수 소환 보조
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
--① 조건: 자신 필드의 스파클 아르카디아 or 싱크로가 직전 체인에서 발동, 상대가 효과 발동
--------------------------------------------------
function s.arcadia_or_synchro(c,tp)
	return c:IsControler(tp) and (c:IsSetCard(0x760) or c:IsType(TYPE_SYNCHRO)) and c:IsType(TYPE_MONSTER)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainNegatable(ev) then return false end
	local ch=ev-1
	if ch<1 then return false end
	local pre_re,pre_p=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	return pre_re and s.arcadia_or_synchro(pre_re:GetHandler(),tp)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) 
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	end
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x760) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		local tc=g:GetFirst()
		if tc then Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP) end
	end
end

--------------------------------------------------
--② 묘지에서 레벨 이하 몬스터 패특소
--------------------------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end
function s.gyfilter(c)
	return c:IsSetCard(0x760) and c:IsMonster() and c:IsLevelAbove(1)
end
function s.handfilter(c,e,tp,lv)
	return c:IsSetCard(0x760) and c:IsLevelBelow(lv) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
		return Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.handfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp,tc:GetLevel())
	local sc=sg:GetFirst()
	if sc then Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP) end
end
