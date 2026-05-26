--코스모 핀드-자력의 마그네틱 & 폴라
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon procedure
	Link.AddProcedure(c,s.matfilter,2,2)
	c:EnableReviveLimit()

	-- Special Summon from GY or banished
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

s.listed_series={0xc04} -- "코스모 핀드" 카드군 지정

function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_FIEND,lc,sumtype,tp) and c:GetAttack()==0 and c:GetDefense()==0
end

-- 링크 몬스터 이외의 악마족 필터 함수
function s.nonLinkFiendFilter(c)
	return c:IsRace(RACE_FIEND) and not c:IsType(TYPE_LINK)
end


-- 소환 조건
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.nonLinkFiendFilter,tp,LOCATION_REMOVED+LOCATION_GRAVE,0,1,nil)
end

-- 비용 처리: 이 카드를 릴리스
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

-- 특수 소환 대상 필터
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_FIEND) and not c:IsType(TYPE_LINK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- 특수 소환 대상 지정
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

-- 특수 소환 실행
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end