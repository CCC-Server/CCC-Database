--프레데터 플랜츠 앰버 프실로피톤
--Predaplant Amber Psilophyton
local s,id=GetID()
function s.initial_effect(c)
	--펜듈럼 소환 방식 등록
	Pendulum.AddProcedure(c)
	
	--[펜듈럼 효과] 펜듈럼 존의 이 카드를 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.sspcon)
	e1:SetTarget(s.ssptg)
	e1:SetOperation(s.sspop)
	c:RegisterEffect(e1)
	
	--[몬스터 효과 1] 일반/특수 소환시 덱에서 "프레데터 플랜츠" 덤핑
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	--[몬스터 효과 2] 융합 소재로 묘지/엑덱 행일 경우 상대 필드에 토큰 생성 + 포식 카운터
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_COUNTER)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.tkcon)
	e4:SetTarget(s.tktg)
	e4:SetOperation(s.tkop)
	c:RegisterEffect(e4)
end

--관련 시리즈 및 카운터 등록
s.listed_series={SET_PREDAPLANT}
s.listed_names={id}
s.counter_place_list={COUNTER_PREDATOR}

--펜듈럼 효과: 조건 (다른 존이 비었거나 프레데터 플랜츠가 있을 때)
function s.sspcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFieldCard(tp,LOCATION_PZONE,1-e:GetHandler():GetSequence())
	return not tc or tc:IsSetCard(SET_PREDAPLANT)
end
function s.ssptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.sspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--몬스터 효과 1: 프레데터 플랜츠 덤핑
function s.tgfilter(c)
	return c:IsSetCard(SET_PREDAPLANT) and not c:IsCode(id) and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

--몬스터 효과 2: 토큰 생성 (상대 필드)
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (r&REASON_FUSION)==REASON_FUSION 
		and (c:IsLocation(LOCATION_GRAVE) or (c:IsFaceup() and c:IsLocation(LOCATION_EXTRA)))
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,1281014510,SET_PREDAPLANT,0x4011,0,0,1,RACE_PLANT,ATTRIBUTE_DARK,POS_FACEUP,1-tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,1281014510,SET_PREDAPLANT,0x4011,0,0,1,RACE_PLANT,ATTRIBUTE_DARK,POS_FACEUP,1-tp) then return end
	
	--사용자 지정 토큰 코드로 생성
	local token=Duel.CreateToken(tp,1281014510)
	if Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP) then
		Duel.BreakEffect()
		--포식 카운터 배치
		token:AddCounter(COUNTER_PREDATOR,1)
		
		--레벨 1로 변경 효과 적용
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetCondition(s.lvcon)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1)
	end
end
function s.lvcon(e)
	return e:GetHandler():GetCounter(COUNTER_PREDATOR)>0
end