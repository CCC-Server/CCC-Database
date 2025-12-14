--Cyber Angel Ritual (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--Activate (Ritual Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--사이버 엔젤 의식 몬스터 필터
function s.ritual_filter(c)
	return c:IsSetCard(0x2093) and bit.band(c:GetType(),TYPE_RITUAL+TYPE_MONSTER)==TYPE_RITUAL+TYPE_MONSTER
end

--릴리스 가능한 몬스터 (펜듈럼 존 포함)
function s.matfilter(c)
	return c:IsReleasable()
end

--엑스트라 덱 릴리스 조건
function s.extra_relmat(tp)
	local g=Group.CreateGroup()
	local eg=Duel.GetFieldGroup(tp,0,LOCATION_MZONE)
	if eg:IsExists(Card.IsSummonLocation,1,nil,LOCATION_EXTRA) then
		local edg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_EXTRA,0,nil)
		if #edg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
			local sg=edg:Select(tp,1,2,nil)
			g:Merge(sg)
		end
	end
	return g
end

--펜듈럼 존 몬스터 레벨을 의식소재용으로 계산하기 위한 레벨 참조 함수
--일반 몬스터는 GetLevel(), 펜듈럼 존 몬스터는 GetOriginalLevel()
function s.GetRitualLevel(c)
	if c:IsLocation(LOCATION_PZONE) then
		return c:GetOriginalLevel()
	else
		return c:GetLevel()
	end
end

--의식 소환 타깃 지정
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ritual_filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

--의식 소환 처리
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.ritual_filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	local tc=tg:GetFirst()
	if not tc then return end

	local mg=Duel.GetRitualMaterial(tp)
	local pz=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_PZONE,0,nil)
	mg:Merge(pz)

	local extrag=s.extra_relmat(tp)
	mg:Merge(extrag)

	local lv=tc:GetLevel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	--의식 소재를 선택할 때 레벨 계산에 s.GetRitualLevel()을 사용
	local mat=mg:SelectWithSumEqual(tp,s.GetRitualLevel,lv,1,63,nil)
	if not mat or #mat==0 then return end
	tc:SetMaterial(mat)
	Duel.ReleaseRitualMaterial(mat)
	Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
	tc:CompleteProcedure()
end

