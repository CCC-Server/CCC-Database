--셀레스티얼 타이탄-수집하는 자 가메논
local s,id=GetID()
function s.initial_effect(c)
	Pendulum.AddProcedure(c)
	-- 1번 효과: 덱에서 카드군 지속 마법 1장 필드에 놓음
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.pltg)
	e1:SetOperation(s.plop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
end

--천사족밖에 일반 소환 / 특수 소환 불가 맹세 효과
function s.splimit(e,c)
    return not c:IsRace(RACE_FAIRY)
end

s.listed_series={0xc02}
function s.plfilter(c,tp)
	return c:IsSetCard(0xc02) and c:IsContinuousSpell() and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK,0,1,nil,tp) end
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end