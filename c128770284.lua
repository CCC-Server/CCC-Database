--스펠크래프트 식신의 주인
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,99)
	--① 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	--② 식신 파괴 후 귀인 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

--재료: 스펠크래프트 몬스터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x761,lc,sumtype,tp)
end

--① 링크 소환 성공시 발동 조건
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--① 특수 소환 대상 설정
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=3
			and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,128770274,e,tp)
			and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,128770273,e,tp)
			and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,128770271,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,3,tp,LOCATION_DECK+LOCATION_HAND)
end

--① 특수 소환 필터
function s.spfilter1(c,code,e,tp)
	return c:IsCode(code) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--① 효과 실행
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<3 then return end
	local c=e:GetHandler()
	local codes={128770274,128770273,128770271}
	for _,code in ipairs(codes) do
		local g=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_DECK+LOCATION_HAND,0,nil,code,e,tp)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:Select(tp,1,1,nil)
			if #sg>0 and Duel.SpecialSummonStep(sg:GetFirst(),0,tp,tp,false,false,POS_FACEUP) then
				--소재로서 릴리스 불가 부여
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UNRELEASABLE_SUM)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				e1:SetValue(1)
				sg:GetFirst():RegisterEffect(e1)
			end
		end
	end
	Duel.SpecialSummonComplete()
end

--② 파괴 & 특수 소환
function s.desfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x762)
end
function s.spfilter2(c,e,tp)
	return c:IsCode(128770277) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) -- "스펠크래프트 식신 귀인"
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	if Duel.Destroy(g,REASON_EFFECT)>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_DECK+LOCATION_HAND,0,1,1,nil,e,tp)
		if #sg>0 and Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)>0 then
			--릴리스 불가
			local tc=sg:GetFirst()
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UNRELEASABLE_SUM)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(1)
			tc:RegisterEffect(e1)
		end
	end
end
