--스펠크래프트의 부활 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 발동 제한 (이 카드명의 카드는 1턴에 1장만 발동 가능)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	--① 묘지의 "스펠크래프트" 몬스터 1장 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,{id,1})
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 묘지 제외 후 "마녀의 가마솥"에 마력 카운터 1개
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCost(aux.bfgcost) -- 이 카드를 제외하는 기본 비용
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
end

--"스펠크래프트 마녀의 가마솥" 코드
s.cauldrontg=128770286

------------------------------------------
--①: 묘지의 "스펠크래프트" 몬스터 특수 소환
------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 메인 페이즈에서만 발동 가능
	return Duel.IsMainPhase()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x761) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

------------------------------------------
--②: 묘지에서 제외 후 카운터 1개 추가
------------------------------------------
function s.cauldronfilter(c)
	return c:IsFaceup() and c:IsCode(s.cauldrontg)
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cauldronfilter,tp,LOCATION_ONFIELD,0,1,nil) end
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.SelectMatchingCard(tp,s.cauldronfilter,tp,LOCATION_ONFIELD,0,1,1,nil):GetFirst()
	if tc then
		tc:AddCounter(COUNTER_SPELL,1)
	end
end
