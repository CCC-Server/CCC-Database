-- 위해의 소멸파
local s,id=GetID()
function s.initial_effect(c)
	-- 카드명 기재 ("가비지 로드", "No.92 위해신룡 Heart-eartH Dragon")
	s.listed_names={44682448, 97403510}

	-- 지속 마법 발동 로직
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ①: 카드의 효과가 발동했을 경우, 자신 필드의 엑시즈 몬스터 1장을 대상으로 발동.
	-- 묘지의 "가비지 로드" 관련 몬스터를 2장까지 엑시즈 소재로 함.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.ovtg)
	e1:SetOperation(s.ovop)
	c:RegisterEffect(e1)

	-- ②: 엔드 페이즈에 발동. 묘지의 "No.92" 특소 + 이 카드를 소재로 함.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- 관련 카드 코드
local CARD_GARBAGE_LORD = 44682448
local CARD_NO_92 = 97403510

-- [안전한 확인 함수] 카드명 기재 여부 확인
function s.is_listed_safe(c,code)
	if not c then return false end
	if c.IsCodeListed and c:IsCodeListed(code) then return true end
	if c.listed_names then
		for _,v in ipairs(c.listed_names) do
			if v==code then return true end
		end
	end
	return false
end

-- ① 효과 필터: 묘지의 "가비지 로드" 관련 몬스터
function s.ovfilter(c)
	return c:IsMonster() and s.is_listed_safe(c,CARD_GARBAGE_LORD)
end

-- ① 효과 Target
function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsType(TYPE_XYZ) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_XYZ)
		and Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_MZONE,0,1,1,nil,TYPE_XYZ)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
end

-- ① 효과 Operation
function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ovfilter),tp,LOCATION_GRAVE,0,1,2,nil)
		if #g>0 then
			Duel.Overlay(tc,g)
		end
	end
end

-- ② 효과 필터: No.92
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_NO_92) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ② 효과 Target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- ② 효과 Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 이 카드가 필드에 존재하고 효과가 무효화되지 않았다면 소재로 함
		if c:IsRelateToEffect(e) and not c:IsImmuneToEffect(e) then
			Duel.BreakEffect()
			c:CancelToGrave()
			Duel.Overlay(tc,c)
		end
	end
end