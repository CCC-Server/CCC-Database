--Dual Dragon Summoner
local s,id=GetID()
function s.initial_effect(c)
	--① 듀얼 몬스터 취급
	Gemini.AddProcedure(c)

	--② 자신 필드에 듀얼 상태 몬스터가 있을 경우 듀얼 상태가 됨
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_GEMINI_STATUS)
	e1:SetCondition(s.gemini_con)
	c:RegisterEffect(e1)

	--③ 드래곤족 듀얼 관련 효과 (효과는 1턴에 1번)
	--③-1: 드래곤족 듀얼 몬스터 1회 추가 일반 소환 허용
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e2:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e2:SetTarget(s.exsumtg)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(Gemini.EffectStatusCondition)
	c:RegisterEffect(e2)

	--③-2: 패의 드래곤족/듀얼 몬스터 1장을 일반 소환
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(Gemini.EffectStatusCondition)
	e3:SetTarget(s.nstg)
	e3:SetOperation(s.nsop)
	c:RegisterEffect(e3)
end

--② 듀얼 상태 처리 조건
function s.gemini_filter(c)
	return c:IsFaceup() and c:IsType(TYPE_GEMINI) and c:IsType(TYPE_EFFECT)
end
function s.gemini_con(e)
	local c=e:GetHandler()
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.gemini_filter,tp,LOCATION_MZONE,0,1,c)
end

--③-1 드래곤족 듀얼 몬스터 추가 일반 소환 허용
function s.exsumtg(e,c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end

--③-2 패의 드래곤족/듀얼 몬스터 일반 소환
function s.nsfilter(c)
	return (c:IsRace(RACE_DRAGON) or c:IsType(TYPE_GEMINI)) and c:IsSummonable(true,nil)
end
function s.nstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) end
end
function s.nsop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local g=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
end

