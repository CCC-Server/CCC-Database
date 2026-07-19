-- 칸티고 트레비아
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 레벨 5 이상의 몬스터를 일반 / 특수 소환했을 경우에 덱/엑덱에서 튜너 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- ②: 패에서 공개 중일 때 특수 소환 (룰 소환)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(s.spcon_rule)
	c:RegisterEffect(e2)
	
	-- ②: 패에서 공개 중일 때 전투 상대 몬스터 효과 무효화
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_DISABLE)
	e3:SetRange(LOCATION_HAND)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetCondition(s.pubcon)
	e3:SetTarget(s.distg)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_DISABLE_EFFECT)
	c:RegisterEffect(e4)
end

-- [① 조건 필터] 자신이 소환한 레벨 5 이상의 몬스터
function s.cfilter(c,tp)
	return c:IsFaceup() and c:IsLevelAbove(5) and c:IsControler(tp)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

-- [① 코스트] 패의 이 카드를 턴 종료시까지 공개
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PUBLIC)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

-- [① 특수 소환 필터] 전사족 / 레벨 5 / 튜너 (동명 제한 삭제)
function s.spfilter(c,e,tp)
	if not (c:IsRace(RACE_WARRIOR) and c:IsLevel(5) and c:IsType(TYPE_TUNER)) then return false end
	if c:IsLocation(LOCATION_EXTRA) then
		return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	else
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
end

-- [① 타겟 지정]
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end

-- [① 효과 처리]
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 여기서 핵심: 튜너 속성을 지우지 않고 '튜너 이외'로도 취급 가능하게 만드는 효과 부여
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_NONTUNER) -- 튜너 이외의 몬스터로 취급 가능하게 함
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- [② 공통: 패 공개 중 조건]
function s.pubcon(e) return e:GetHandler():IsPublic() end

-- [② 특수 소환 조건]
function s.spcon_rule(e,c)
	if c==nil then return true end
	return e:GetHandler():IsPublic() and Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
end

-- [② 전투 무효화 타겟]
function s.distg(e,c)
	local tp=e:GetHandlerPlayer()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(tp) and bc:IsFaceup() and (bc:IsLevel(5) or bc:IsLevel(10))
end