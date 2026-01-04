--마린세스 펄 쉘
--Marincess Pearl Shell
local s,id=GetID()
function s.initial_effect(c)
	--①: 자신/상대 턴에 특수 소환 + 링크 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--②: 링크 소재로 묘지로 보내졌을 경우 묘지 특소
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MARINCESS}

-- ①번 효과 필터
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MARINCESS)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 소재로 쓰일 장착 카드 필터 (마법/함정 존의 마린세스 링크 몬스터)
function s.matfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MARINCESS) and c:IsType(TYPE_LINK) and c:IsLocation(LOCATION_SZONE)
end

-- 링크 소환 가능한 마린세스 체크
function s.lnkfilter(c,mg)
	return c:IsSetCard(SET_MARINCESS) and c:IsLinkSummonable(mg)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 특수 소환 가능 여부
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 
			or not e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
		
		-- 링크 소환 가능 여부 시뮬레이션 (바질리코크 방식)
		local e1,e2=s.tempregister(e,tp)
		local res=Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_EXTRA,0,1,nil,TYPE_LINK)
		e1:Reset()
		e2:Reset()
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 1. 패에서 특수 소환
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 2. 장착 카드를 소재로 쓰기 위한 일시적 효과 등록
		local e1,e2=s.tempregister(e,tp)
		
		-- 3. 링크 소환 실행 여부 확인
		local g=Duel.GetMatchingGroup(s.lnkfilter,tp,LOCATION_EXTRA,0,nil,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=Duel.SelectMatchingCard(tp,s.lnkfilter,tp,LOCATION_EXTRA,0,1,1,nil,nil):GetFirst()
			if sc then
				-- 링크 소환 실행
				Duel.LinkSummon(tp,sc,nil)
				
				-- 소환 성공 시 소재 규칙 리셋 (바질리코크 로직)
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
				e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e3:SetCode(EVENT_SPSUMMON_SUCCESS)
				e3:SetOperation(function(ev_e)
					e1:Reset()
					e2:Reset()
					ev_e:Reset()
				end)
				sc:RegisterEffect(e3)
			else
				e1:Reset()
				e2:Reset()
			end
		else
			e1:Reset()
			e2:Reset()
		end
	end
end

-- [핵심] 장착 상태의 카드를 몬스터처럼 취급하여 소재로 등록하는 함수
function s.tempregister(e,tp)
	-- 1. 소재 범위 확장: 마법/함정 존의 마린세스 링크를 소재 그룹에 포함
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_MATERIAL)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET|EFFECT_FLAG_SET_AVAILABLE)
	e1:SetTargetRange(1,0)
	e1:SetOperation(aux.TRUE)
	e1:SetValue(s.extraval)
	Duel.RegisterEffect(e1,tp)
	
	-- 2. 타입 추가: 소재 선택 시에만 일시적으로 "몬스터" 타입을 부여
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_ADD_TYPE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	e2:SetCondition(s.addtypecon)
	e2:SetTarget(aux.TargetBoolFunction(s.matfilter)) -- 마법/함정 존의 마린세스 링크만 타겟
	e2:SetValue(TYPE_MONSTER)
	Duel.RegisterEffect(e2,tp)
	
	return e1,e2
end

function s.extraval(chk,summon_type,e,...)
	if chk==0 then
		local tp,sc=...
		-- 소환할 대상이 마린세스인 경우에만 규칙 적용
		if summon_type~=SUMMON_TYPE_LINK or not (sc and sc:IsSetCard(SET_MARINCESS)) then
			return Group.CreateGroup()
		else
			-- 규칙이 활성화되었음을 알리는 플래그 설정
			Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
			return Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_SZONE,0,nil)
		end
	elseif chk==2 then
		-- 소환 처리 완료 후 플래그 해제
		Duel.ResetFlagEffect(e:GetHandlerPlayer(),id)
	end
end

function s.addtypecon(e)
	-- extraval에서 등록된 플래그가 있을 때만 몬스터로 취급
	return Duel.GetFlagEffect(e:GetHandlerPlayer(),id)>0
end

-- ②번 효과 필터 및 로직 (링크 소재로 묘지 전송 시 특소)
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_LINK
end
function s.spfilter2(c,e,tp)
	return c:IsSetCard(SET_MARINCESS) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end