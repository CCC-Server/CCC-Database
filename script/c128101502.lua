-- 가비지 임펄스
local s,id=GetID()
function s.initial_effect(c)
	-- "가비지 로드"의 카드명이 쓰여짐
	s.listed_names={44682448}

	-- ①: "가비지 로드" 또는 "가비지 로드"의 카드명이 쓰여진 몬스터가 필드 / 묘지에 존재할 경우, 이 카드는 패에서 특수 소환할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ②: 이 카드를 일반 소환 / 특수 소환했을 경우에 발동할 수 있다. 서치 및 추가 특소.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

-- "가비지 로드"의 코드
local CARD_GARBAGE_LORD = 44682448

-- [안전한 확인 함수] 가비지 로드가 기재되어 있는지 확인
function s.is_listed_safe(c)
	if not c then return false end
	-- 1. 코어 함수가 있으면 시도
	if c.IsCodeListed and c:IsCodeListed(CARD_GARBAGE_LORD) then return true end
	-- 2. Lua 테이블(listed_names)이 있으면 직접 확인 (커스텀 카드 호환)
	if c.listed_names then
		for _,code in ipairs(c.listed_names) do
			if code==CARD_GARBAGE_LORD then return true end
		end
	end
	return false
end

-- ① 효과 필터
function s.spfilter(c)
	-- "가비지 로드" 본체이거나 카드명이 쓰여진 몬스터
	return c:IsMonster() and (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c)) 
		and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end

-- ① 효과 조건
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)
end

-- ② 효과 서치 필터
function s.thfilter(c)
	-- "가비지 임펄스" 이외, "가비지 로드" 관련 카드 (본체 포함)
	return (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c)) 
		and not c:IsCode(id) and c:IsAbleToHand()
end

-- ② 효과 추가 특소 필터 ("가비지 로드" 본체)
function s.spfilter2(c,e,tp)
	return c:IsCode(CARD_GARBAGE_LORD) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ② 효과 Target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	
	-- LP 조건 만족 시 특수 소환 가능성 알림
	if Duel.GetLP(tp)<Duel.GetLP(1-tp) then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	end
end

-- ② 효과 Operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
			
			-- 추가 효과 처리
			if Duel.GetLP(tp)<Duel.GetLP(1-tp) 
				and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then 
				
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
				if #sg>0 then
					Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
				end
			end
		end
	end
end