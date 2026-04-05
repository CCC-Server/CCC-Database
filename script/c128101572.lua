local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 조건: 싱크로 튜너 + 싱크로 비튜너 2장 이상
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_SYNCHRO),1,1,Synchro.NonTunerEx(Card.IsType,TYPE_SYNCHRO),2,99)
	
	-- 묘지 제외 특수 소환 (접촉 융합 스타일의 소환)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetTarget(s.sprtg)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)
	
	-- ①: 효과 발동 무효 및 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.discon)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)
	
	-- ②: 묘지/제외 몬스터를 덱으로 되돌림
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
	local e2_rem=e2:Clone()
	e2_rem:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e2_rem)
	
	-- ③: 묘지로 보내졌을 경우 "TG" 싱크로 소환 취급 특소
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.spcon3)
	e3:SetTarget(s.sptg3)
	e3:SetOperation(s.spop3)
	c:RegisterEffect(e3)
end

-- 묘지 특소 조건 필터
function s.sprfilter1(c)
	return c:IsType(TYPE_SYNCHRO) and c:IsType(TYPE_TUNER) and c:IsAbleToRemoveAsCost()
end
function s.sprfilter2(c)
	return c:IsType(TYPE_SYNCHRO) and not c:IsType(TYPE_TUNER) and c:IsAbleToRemoveAsCost()
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg1=Duel.GetMatchingGroup(s.sprfilter1,tp,LOCATION_GRAVE,0,nil)
	local rg2=Duel.GetMatchingGroup(s.sprfilter2,tp,LOCATION_GRAVE,0,nil)
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 
		and #rg1>=1 and #rg2>=2
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local rg1=Duel.GetMatchingGroup(s.sprfilter1,tp,LOCATION_GRAVE,0,nil)
	local rg2=Duel.GetMatchingGroup(s.sprfilter2,tp,LOCATION_GRAVE,0,nil)
	local g=Group.CreateGroup()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=rg1:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=rg2:Select(tp,2,2,nil)
	g:Merge(g1)
	g:Merge(g2)
	if #g==3 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	g:DeleteGroup()
end

-- ① 효과 무효
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
end

-- ② 덱 되돌리기
function s.tdfilter(c,e)
	return c:IsMonster() and c:IsCanBeEffectTarget(e) and c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) and s.tdfilter(chkc,e) end
	if chk==0 then return eg:IsExists(s.tdfilter,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=eg:FilterSelect(tp,s.tdfilter,1,1,nil,e)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-- ③ 유언 효과
function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end
function s.spfilter3(c,e,tp)
	return c:IsSetCard(0x27) and c:IsType(TYPE_SYNCHRO) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end
function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_SYNCHRO)>0
		and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_SYNCHRO)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end