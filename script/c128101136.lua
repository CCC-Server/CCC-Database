--Sphinx Domain 개선본 with 릴리스 효과
local s,id=GetID()
function s.initial_effect(c)
	-- 필드 마법 발동
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ① 몬스터 효과 체인시 발동 → 암석족 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_FZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ② 암석족 제외 방지
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_REMOVE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.rmlimit)
	c:RegisterEffect(e2)

	-- ③ 필드존에서 묘지 → 암석족 회수
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

-- ① 조건: 몬스터 효과 발동
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER)
end

-- 스핑크스 몬스터 존재 여부
function s.sphinx_filter(c)
	return c:IsFaceup() and c:IsSetCard(0x20cf)
end

-- 대상 가능: 내 암석족 or 상대 앞면 (스핑크스 조건 하에)
function s.tgfilter(c,tp,e)
	local lv=c:GetLevel()
	return c:IsFaceup()
		and (
			(c:IsRace(RACE_ROCK) and c:IsControler(tp))
			or (Duel.IsExistingMatchingCard(s.sphinx_filter,tp,LOCATION_MZONE,0,1,nil) and c:IsControler(1-tp))
		)
		and lv>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp,lv)
end

-- 특소 가능 대상 필터
function s.spfilter(c,e,tp,lv)
	return c:IsRace(RACE_ROCK) and c:IsLevel(lv) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- 대상 지정
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return s.tgfilter(chkc,tp,e) and chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp,e)
	e:SetLabelObject(g:GetFirst())
end

-- 특수 소환 실행 (릴리스 포함)
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=e:GetLabelObject()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	local lv=tc:GetLevel()
	local owner=tc:GetControler()

	-- 릴리스 처리
	if Duel.Release(tc,REASON_COST)~=1 then return end

	-- 덱에서 특수 소환
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,function(c) return s.spfilter(c,e,tp,lv) end,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ② 제외 방지
function s.rmlimit(e,c,tp,r)
	return c:IsRace(RACE_ROCK)
end

-- ③ 필드존 → 묘지 조건
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_FZONE) and c:IsFaceup()
end

-- 묘지에서 암석족 서치
function s.thfilter(c)
	return c:IsRace(RACE_ROCK) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
