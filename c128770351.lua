local s,id=GetID()
function s.initial_effect(c)
	-----------------------------------------
	-- E0: 발동 제한 (1턴에 1장)
	-----------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+100)
	c:RegisterEffect(e0)

	-----------------------------------------
	-- 글로벌 카운터: "요정향" 특수 소환 횟수 추적
	-----------------------------------------
	if not s.global_check then
		s.global_check=true
		s[0]=0
		s[1]=0
		-- 특수 소환 성공 시 체크
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
		-- 드로우 페이즈 시작 시 초기화
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge2:SetOperation(function()
			s[0]=0
			s[1]=0
		end)
		Duel.RegisterEffect(ge2,0)
	end

	-----------------------------------------
	-- E1: 필드에 몬스터 없음 → "요정향" 특소 + 엑덱 제한
	-----------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-----------------------------------------
	-- E2: "요정향"을 3번 특소했을 경우, 묘지에서 제외하고 의사 싱크로 소환
	-----------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.sccon)
	e2:SetTarget(s.sctg)
	e2:SetOperation(s.scop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------
-- 글로벌 체크: "요정향" 특소 횟수 카운팅
-----------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		if tc:IsSetCard(0x767) and tc:IsSummonType(SUMMON_TYPE_SPECIAL) then
			local p=tc:GetSummonPlayer()
			s[p]=s[p]+1
		end
	end
end

-----------------------------------------------------
-- E1 조건: 필드에 몬스터 없음
-----------------------------------------------------
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x767) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)

		-- 엑스트라 덱 특수 소환 제한: "요정향" 싱크로/링크만 가능
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.exlimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

		-- Client Hint
		aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,2),nil)
	end
end

function s.exlimit(e,c,sump,sumtype,sumpos,targetp,se)
	if not c:IsLocation(LOCATION_EXTRA) then return false end
	if c:IsSetCard(0x767) and (c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_LINK)) then return false end
	return true
end

-----------------------------------------------------
-- E2 조건: "요정향" 몬스터 3번 이상 특수 소환했는가
-----------------------------------------------------
function s.sccon(e,tp,eg,ep,ev,re,r,rp)
	return s[tp]>=3
end

function s.tuner_filter(c)
	return c:IsSetCard(0x767) and c:IsType(TYPE_TUNER) and c:IsAbleToRemove()
end
function s.nontuner_filter(c)
	return c:IsSetCard(0x767) and not c:IsType(TYPE_TUNER) and c:IsAbleToRemove()
end
function s.synfilter(c,e,tp,lv)
	return c:IsSetCard(0x767) and c:IsType(TYPE_SYNCHRO) and c:IsLevel(lv)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local tg=Duel.GetMatchingGroup(s.tuner_filter,tp,LOCATION_GRAVE,0,nil)
		local ntg=Duel.GetMatchingGroup(s.nontuner_filter,tp,LOCATION_GRAVE,0,nil)
		for tc in tg:Iter() do
			for nc in ntg:Iter() do
				local lv=tc:GetLevel() + nc:GetLevel()
				if Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,lv) then
					return true
				end
			end
		end
		return false
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,2,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.scop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local tg=Duel.SelectMatchingCard(tp,s.tuner_filter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #tg==0 then return end
	local tuner=tg:GetFirst()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local ntg=Duel.SelectMatchingCard(tp,s.nontuner_filter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #ntg==0 then return end
	local nontuner=ntg:GetFirst()

	local lv=tuner:GetLevel() + nontuner:GetLevel()
	local rg=Group.FromCards(tuner,nontuner)
	if Duel.Remove(rg,POS_FACEUP,REASON_COST)==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,lv)
		if #sg>0 then
			Duel.SpecialSummon(sg,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
			sg:GetFirst():CompleteProcedure()
		end
	end
end

-----------------------------------------------------
-- ② 의사 싱크로 소환 : 조건
-----------------------------------------------------
function s.sccon(e,tp,eg,ep,ev,re,r,rp)
	return s[tp]>=3
end

-----------------------------------------------------
-- ② 의사 싱크로 : 대상 지정
-----------------------------------------------------
function s.tunerfilter(c)
	return c:IsSetCard(0x767) and c:IsType(TYPE_TUNER) and c:IsAbleToRemove()
end
function s.ntfilter(c)
	return c:IsSetCard(0x767) and not c:IsType(TYPE_TUNER) and c:IsAbleToRemove()
end

function s.syncfilter(c,lv)
	return c:IsSetCard(0x767) and c:IsType(TYPE_SYNCHRO) and c:IsLevel(lv)
end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tunerfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.ntfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-----------------------------------------------------
-- ② 의사 싱크로 : 처리
-----------------------------------------------------
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(s.tunerfilter,tp,LOCATION_GRAVE,0,nil)
	local g2=Duel.GetMatchingGroup(s.ntfilter,tp,LOCATION_GRAVE,0,nil)
	local mg=Group.CreateGroup()

	-- 제외할 재료 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local tg1=g1:Select(tp,1,1,nil)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local tg2=g2:Select(tp,1,99,nil) -- 여러 장 가능

	mg:Merge(tg1)
	mg:Merge(tg2)

	local lv=0
	for tc in aux.Next(mg) do lv=lv+tc:GetLevel() end

	if Duel.Remove(mg,POS_FACEUP,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.syncfilter,tp,LOCATION_EXTRA,0,1,1,nil,lv):GetFirst()

	if sc then
		Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
