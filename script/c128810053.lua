--셀레스티얼 타이탄-현자 에아
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc02),2)
	--Must be properly summoned before being revived
	c:EnableReviveLimit()
	--Place 2 "Celestial Titan" monsters from your Deck to your Pendulum Zones
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
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	-- 비용: 이 카드를 릴리스
	e2:SetCost(s.relcost)
	-- 대상: 패의 천사족 튜너
	e2:SetTarget(s.target)
	-- 처리: 특수 소환 실행
	e2:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
--천사족밖에 일반 소환 / 특수 소환 불가 맹세 효과
function s.splimit(e,c)
	return not c:IsRace(RACE_FAIRY)
end

s.listed_series={0xc02}
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e2,tp)
end
function s.pcfilter(c)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
	--Activation legality
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.pcfilter,tp,LOCATION_DECK,0,nil)
		return Duel.CheckLocation(tp,LOCATION_PZONE,0) and Duel.CheckLocation(tp,LOCATION_PZONE,1)
			and g:GetClassCount(Card.GetCode)>=2
	end
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
	--Place 2 monsters in your Pendulum Zones
	local g=Duel.GetMatchingGroup(s.pcfilter,tp,LOCATION_DECK,0,nil)
	if Duel.CheckLocation(tp,LOCATION_PZONE,0) and Duel.CheckLocation(tp,LOCATION_PZONE,1)
		and g:GetClassCount(Card.GetCode)>=2 then
		local pg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.dncheck,1,tp,HINTMSG_TOFIELD)
		if #pg~=2 then return end
		local pc1,pc2=pg:GetFirst(),pg:GetNext()
		if Duel.MoveToField(pc1,tp,tp,LOCATION_PZONE,POS_FACEUP,false) then
			if Duel.MoveToField(pc2,tp,tp,LOCATION_PZONE,POS_FACEUP,false) then
				
				pc2:SetStatus(STATUS_EFFECT_ENABLED,true)
			end
			pc1:SetStatus(STATUS_EFFECT_ENABLED,true)
		end
	end
end

-- 필터: 천사족(RACE_FAIRY)이면서 튜너(TYPE_TUNER)이고 특수 소환 가능한 몬스터
function s.filter(c,e,tp)
	return c:IsRace(RACE_FAIRY) and c:IsType(TYPE_TUNER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.relcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e2,tp)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 비용으로 자신을 릴리스하므로, 자신을 포함하여 메인 몬스터 존의 빈 공간을 계산 (GetMZoneCount)
	if chk==0 then return Duel.GetMZoneCount(tp,e:GetHandler())>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	-- 효과 처리 시점에 몬스터 존에 자리가 있는지 다시 확인
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end