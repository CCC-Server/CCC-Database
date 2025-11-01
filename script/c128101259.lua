--암군 페로단테 융합체
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- "암군 페로단테"(128101253) + 어둠 속성 몬스터
	Fusion.AddProcMix(c,true,true,128101253,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK))

	--① 융합 소환 성공 시 또는 상대 몬스터 특수 소환 시: 필드 1장 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	local e1b=Effect.CreateEffect(c)
	e1b:SetDescription(aux.Stringid(id,0))
	e1b:SetCategory(CATEGORY_DESTROY)
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1b:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1b:SetRange(LOCATION_MZONE)
	e1b:SetCountLimit(1,{id,1})
	e1b:SetCondition(s.descon2)
	e1b:SetTarget(s.destg)
	e1b:SetOperation(s.desop)
	c:RegisterEffect(e1b)

	--② (Quick) 묘지의 "암군" 몬스터 특소 → 상대 필드 몬스터 존재 시 전사족 융합
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_END_PHASE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc45}
s.listed_names={128101253}

-----------------------------------------------------------
--① 파괴 효과
-----------------------------------------------------------
function s.descon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(sc,pt)
		return sc:IsSummonPlayer(1-pt) and sc:IsLocation(LOCATION_MZONE)
	end,1,nil,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-----------------------------------------------------------
--② "암군" 특소 + (조건부) 전사족 융합 소환
-----------------------------------------------------------
function s.gyfilter(c,e,tp)
	return c:IsSetCard(0xc45) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.gyfilter(chkc,e,tp) end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.gyfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.gyfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)<=0 then return end

	-- 상대 필드에 몬스터가 있을 경우, 전사족 융합 시도
	if Duel.IsExistingMatchingCard(Card.IsMonster,tp,0,LOCATION_MZONE,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.BreakEffect()

		local params={
			fusfilter = function(c) return c:IsType(TYPE_FUSION) and c:IsRace(RACE_WARRIOR) end
		}
		if Fusion.SummonEffTG(params)(e,tp,eg,ep,ev,re,r,rp,0) then
			Fusion.SummonEffOP(params)(e,tp,eg,ep,ev,re,r,rp)
		end
	end
end
