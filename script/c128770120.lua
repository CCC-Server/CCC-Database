--한빙 마요괴ㅡ설녀
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건: 언데드족 몬스터 2장 이상
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,2,s.lcheck)

	--①: 필드에 1장만 존재 가능
	c:SetUniqueOnField(1,0,id)

	--②: 링크 소환 성공 시, 언데드족 이외 몬스터 효과 봉쇄
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.effcon)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.operation2)
	c:RegisterEffect(e1)

	--③: 필드를 벗어나면 엑스트라 덱으로 되돌리고 마요괴 1장 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon3)
	e2:SetTarget(s.sptg3)
	e2:SetOperation(s.spop3)
	c:RegisterEffect(e2)
end

--링크 소재 체크: 전부 언데드족이어야 함
function s.lcheck(g,lc,sumtype,tp)
	return g:FilterCount(Card.IsRace,nil,RACE_ZOMBIE)==#g
end

--②: 링크 소환 성공 조건
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--②: 언데드족 이외 몬스터 효과 봉쇄
function s.operation2(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_TRIGGER)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.actlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.actlimit(e,c)
	return not c:IsRace(RACE_ZOMBIE)
end

--③: 필드를 벗어난 경우 → 엑스트라 덱으로 되돌리고 마요괴 특수 소환
function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spfilter3(c,e,tp)
	return c:IsSetCard(0x121) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
			and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_GRAVE,0,1,nil,e,tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) then return end
	if Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
