--셀레스티얼 타이탄-현자 에아
-- 카드 ID 정의
local s,id=GetID()

function s.initial_effect(c)
	-- 링크 소환: 카드군 0xc02 몬스터 2장
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc02),2)
	c:EnableReviveLimit()
	
	-- 1번 효과: 특수 소환 성공시 펜듈럼 존에 세팅
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.pltg)
	e1:SetOperation(s.plop)
	c:RegisterEffect(e1)
	
	-- 2번 효과: 이 카드를 릴리스하고 패에서 천사족 튜너 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100) -- 적절한 카드명 제약 추가
	e2:SetCost(s.relcost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2) -- 수정됨: e1이 아닌 e2를 등록해야 함
end

s.listed_series={0xc02}

-- 천사족 이외의 몬스터 특수 소환을 카운트하는 카운터 등록
Duel.AddCustomActivityCounter(id,ACTIVITY_SPSUMMON,function(c) return c:IsRace(RACE_FAIRY) end)

-- 제약 함수
function s.splimit(e,c,sump,sumtyp,sumpos,targetp,se)
	return not c:IsRace(RACE_FAIRY)
end

-- 1번 효과 코스트
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e2,tp)
end

-- 펜듈럼 세팅 필터 및 타겟
function s.pcfilter(c)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.pcfilter,tp,LOCATION_DECK,0,nil)
		return Duel.CheckLocation(tp,LOCATION_PZONE,0) and Duel.CheckLocation(tp,LOCATION_PZONE,1)
			and g:GetClassCount(Card.GetCode)>=2
	end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
	if not (Duel.CheckLocation(tp,LOCATION_PZONE,0) and Duel.CheckLocation(tp,LOCATION_PZONE,1)) then return end
	local g=Duel.GetMatchingGroup(s.pcfilter,tp,LOCATION_DECK,0,nil)
	if g:GetClassCount(Card.GetCode)>=2 then
		local pg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.dncheck,1,tp,HINTMSG_TOFIELD)
		if #pg==2 then
			local pc1=pg:GetFirst()
			local pc2=pg:GetNext()
			Duel.MoveToField(pc1,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
			Duel.MoveToField(pc2,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
		end
	end
end

-- 2번 효과 코스트 (제약 + 릴리스)
function s.relcost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- chk==0 일 때 모든 조건을 한 번에 확인
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 
		and e:GetHandler():IsReleasable() end
	
	-- 릴리스 실행
	Duel.Release(e:GetHandler(),REASON_COST)
	
	-- 제약 등록
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e2,tp)
end

-- 특수 소환 필터 및 타겟
function s.filter(c,e,tp)
	return c:IsRace(RACE_FAIRY) and c:IsType(TYPE_TUNER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetMZoneCount(tp,e:GetHandler())>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end