--Tramid Revenge of Sphinx
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 특수 소환 제한: "트라미드" 카드의 효과 또는 자신 효과로만
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	--① 암석족 릴리스로 패에서 특소
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(TIMING_MAIN_END+TIMINGS_CHECK_MONSTER)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e,tp) return Duel.IsMainPhase() end)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: 프리체인 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--③: 필드 마법 교체 (상대 턴)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.fldcon)
	e3:SetTarget(s.fldtg)
	e3:SetOperation(s.fldop)
	c:RegisterEffect(e3)
end

-- ✅ 특수 소환 제한: 자신 효과이거나 트라미드 카드 효과일 때만 허용
function s.splimit(e,se,sp,st)
	local c=e:GetHandler()
	return se and (se:GetHandler():IsSetCard(0xe2) or se:GetHandler()==c)
end

--① 릴리스로 특수 소환
function s.cfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_ROCK) and c:IsReleasable()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroup(tp,s.cfilter,1,nil) end
	local g=Duel.SelectReleaseGroup(tp,s.cfilter,1,1,nil)
	Duel.Release(g,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--② 자신 + 상대 파괴
function s.selfdesfilter(c)
	return c:IsFaceup() and (c:IsRace(RACE_ROCK) or c:IsType(TYPE_FIELD))
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.IsExistingTarget(s.selfdesfilter,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingTarget(Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,s.selfdesfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,#g1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--③ 필드 마법 교체
function s.fldcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end
function s.fldfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD)
		and Duel.IsExistingMatchingCard(s.fldnewfilter,tp,LOCATION_DECK,0,1,nil,c:GetCode(),tp)
end
function s.fldnewfilter(c,code,tp)
	return c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD) and not c:IsCode(code)
		and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.fldtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fldfilter,tp,LOCATION_ONFIELD,0,1,nil,tp) end
end
function s.fldop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.fldfilter,tp,LOCATION_ONFIELD,0,1,1,nil,tp)
	local tc=g:GetFirst()
	if tc and Duel.SendtoGrave(tc,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_GRAVE) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local sg=Duel.SelectMatchingCard(tp,s.fldnewfilter,tp,LOCATION_DECK,0,1,1,nil,tc:GetCode(),tp)
		if #sg>0 then
			Duel.ActivateFieldSpell(sg:GetFirst(),e,tp)
		end
	end
end
