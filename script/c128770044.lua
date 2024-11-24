local s,id=GetID()
function s.initial_effect(c)
	--① 효과: 패에서 특수 소환 및 싱크로 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id) -- 1턴에 1번 사용 제한
	e1:SetHintTiming(TIMING_MAIN_END)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

   local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,1))
e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_TO_GRAVE)
e2:SetProperty(EFFECT_FLAG_DELAY)
e2:SetCountLimit(1,{id,1}) -- 1턴에 1번 사용 제한
e2:SetCondition(s.spcon2) -- 발동 조건 추가
e2:SetTarget(s.sptg2)
e2:SetOperation(s.spop2)
c:RegisterEffect(e2)
end

--① 효과: 패에서 특수 소환 및 싱크로 소환
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() -- 메인 페이즈에서만 발동 가능
end
function s.filter(c)
	return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER) and c:IsAttribute(ATTRIBUTE_LIGHT)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)) then return end
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and Duel.GetLocationCountFromEx(tp,tp,tc)>0 then
		local sg=Group.FromCards(c,tc)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sync=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsSynchroSummonable),tp,LOCATION_EXTRA,0,1,1,nil,nil,sg)
		if #sync>0 and sync:GetFirst():IsSetCard(0x754) then -- "매지컬★시스터" 세트 코드 체크
			Duel.SynchroSummon(tp,sync:GetFirst(),nil,sg)
		end
	end
end

--② 효과: 필드에서 묘지로 보내졌을 경우 특수 소환
function s.spfilter(c,e,tp)
	return c:IsLevel(4) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_SPELLCASTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	-- 필드에서 묘지로 보내졌을 때만 발동 가능
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end