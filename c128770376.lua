local s,id=GetID()
function s.initial_effect(c)
	-- E1: 필드/묘지에서 레벨 5로 취급
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e1:SetValue(5)
	c:RegisterEffect(e1)

	-- E2: 특수 소환 조건 (라바르 카드 존재 시)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	c:RegisterEffect(e2)

	-- E3: 싱크로 소재로 묘지로 보내졌을 때 제외 화염속성 특소
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.spcon2)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- 🔸 E2: 특수 소환 조건 (라바르 카드가 필드/묘지에 있을 경우)
function s.lavalfilter(c)
	return c:IsSetCard(0x39)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.lavalfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil)
end

-- 🔸 E3: 싱크로 소재로 묘지로 보내졌을 때 조건
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_SYNCHRO
end

-- 🔸 E3: 대상 지정 - 제외된 화염 속성 몬스터 1장
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.spfilter,tp,LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_REMOVED,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

-- 🔸 E3: 처리 - 대상 화염 몬스터 특수 소환
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 성공 시 추가 처리 가능 (생략)
	end
end
