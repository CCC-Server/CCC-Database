--명왕룡의 제단
local s,id=GetID()
function s.initial_effect(c)
	--기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}

	--①: 발동 시 처리 (덱에서 카운터 함정 세트 + 즉시 발동 권한 부여)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--②: 세트한 턴에 카운터 함정 발동 허용 (지속 효과 버전)
	--이 효과는 덱에서 그냥 세트한 다른 카드들을 위해 남겨둡니다.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	e2:SetTarget(s.acttg)
	c:RegisterEffect(e2)
	
	--③: 릴리스되었을 경우 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_RELEASE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

function s.safe_check_listed(c, target_code)
	if not c.listed_names then return false end
	for _,code in ipairs(c.listed_names) do
		if code==target_code then return true end
	end
	return false
end

--①: 세트 필터
function s.setfilter(c)
	return c:IsType(TYPE_COUNTER) and s.safe_check_listed(c,24857466) and c:IsSSetable()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local tc=g:Select(tp,1,1,nil):GetFirst()
		if tc and Duel.SSet(tp,tc)~=0 then
			-- [핵심 수정] 세트한 카드에 즉시 발동 권한 부여
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end

--②: 카운터 함정 대상
function s.acttg(e,c)
	return c:IsType(TYPE_COUNTER)
end

--③: 릴리스 조건 및 특수 소환
function s.cfilter(c,tp)
	return c:IsPreviousControler(tp)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.spfilter(c,e,tp,codes)
	return (c:IsCode(24857466) or s.safe_check_listed(c,24857466))
		and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and not c:IsCode(table.unpack(codes))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rg=eg:Filter(s.cfilter,nil,tp)
	local codes={}
	for rc in aux.Next(rg) do table.insert(codes,rc:GetCode()) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,codes) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local rg=eg:Filter(s.cfilter,nil,tp)
	local codes={}
	for rc in aux.Next(rg) do table.insert(codes,rc:GetCode()) end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,codes)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end