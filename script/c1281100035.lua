-- 대파괴수결전병기 - 옥시전 디스트로이어
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터
local CODE_WATERFRONT=56111151 -- KYOUTOU 워터프론트
local CODE_KAGHIDORA=124161398 -- 중격괴수황 썬더 카기도라 (임시 코드)

function s.initial_effect(c)
	-- ①: 발동 (카운터 + 추가 효과)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER+CATEGORY_SPECIAL_SUMMON+CATEGORY_CONTROL)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- ②: 묘지 제외 후 융합
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.fuscon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
	
	-- 묘지로 보내진 턴 체크를 위한 등록
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TO_GRAVE)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end
s.listed_names={CODE_WATERFRONT, CODE_KAGHIDORA}
s.listed_series={0xd3, 0xc82} -- 파괴수, 대괴수결전병기
s.counter_list={COUNTER_KAIJU}

-- ① 효과: 체인 제한 (이번 턴 특소된 몬스터 효과 발동 불가)
function s.chainlm(e,rp,tp)
	return not (e:IsActiveType(TYPE_MONSTER) and e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL) and e:GetHandler():IsStatus(STATUS_SUMMON_TURN))
end

-- ① 효과: 카운터 놓기 필터
function s.ctfilter(c)
	return c:IsCanAddCounter(COUNTER_KAIJU,3)
end

-- ① 효과: 덱 특소 필터
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xd3) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ① 효과: 컨트롤 탈취 필터
function s.ctrlfilter(c)
	return c:IsSetCard(0xd3) and c:IsControlerCanBeChanged()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.SetChainLimit(s.chainlm)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,3,0,COUNTER_KAIJU)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 카운터 놓기
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
	local g=Duel.SelectMatchingCard(tp,s.ctfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		local tc=g:GetFirst()
		tc:AddCounter(COUNTER_KAIJU,3)
		
		-- 2. 워터프론트 확인 및 추가 효과
		if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CODE_WATERFRONT),tp,LOCATION_ONFIELD,0,1,nil) then
			-- 선택지 가능 여부 확인
			-- id+100: 덱 특소 사용함, id+200: 컨트롤 탈취 사용함
			local b1=Duel.GetFlagEffect(tp,id+100)==0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
			local b2=Duel.GetFlagEffect(tp,id+200)==0 
				and Duel.IsExistingMatchingCard(s.ctrlfilter,tp,0,LOCATION_MZONE,1,nil)
			
			local op=0
			if b1 and b2 then
				op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
			elseif b1 then
				op=Duel.SelectOption(tp,aux.Stringid(id,2))
			elseif b2 then
				op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
			else
				return -- 선택할 수 있는 효과가 없음
			end
			
			if op==0 then -- 덱 특소
				Duel.RegisterFlagEffect(tp,id+100,RESET_PHASE+PHASE_END,0,1)
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
				if #sg>0 then
					Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
				end
			else -- 컨트롤 탈취
				Duel.RegisterFlagEffect(tp,id+200,RESET_PHASE+PHASE_END,0,1)
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
				local sg=Duel.SelectMatchingCard(tp,s.ctrlfilter,tp,0,LOCATION_MZONE,1,1,nil)
				if #sg>0 then
					Duel.GetControl(sg,tp)
				end
			end
		end
	end
end

-- ② 효과: 묘지로 보내진 턴 체크
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	for tc in aux.Next(eg) do
		if tc:IsCode(id) then
			-- 묘지로 간 턴 번호를 라벨로 저장
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,Duel.GetTurnCount())
		end
	end
end

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local turn=c:GetFlagEffectLabel(id)
	-- 라벨(묘지로 간 턴)이 있고, 그게 이번 턴이면 발동 불가
	return not (turn and turn==Duel.GetTurnCount())
end

-- 융합 필터: 필드 (자신/상대)
function s.ffilter_field(c,e,tp,m)
	return c:IsCode(CODE_KAGHIDORA) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
		and c:CheckFusionMaterial(m,nil,tp)
end

-- 융합 필터: 묘지 (파괴수 몬스터)
function s.matfilter_grave(c)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeck()
end

-- 융합 몬스터 필터 (묘지 소재용)
function s.ffilter_grave(c,e,tp,m)
	return c:IsCode(CODE_KAGHIDORA) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
		and c:CheckFusionMaterial(m,nil,tp)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 옵션 1: 필드 융합 (자신/상대 필드)
		local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsOnField,nil)
		local mg1_opp=Duel.GetFusionMaterial(1-tp):Filter(Card.IsOnField,nil)
		mg1:Merge(mg1_opp)
		local res1=Duel.IsExistingMatchingCard(s.ffilter_field,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1)
		
		-- 옵션 2: 묘지 덱 융합 (파괴수 3장까지)
		local mg2=Duel.GetMatchingGroup(s.matfilter_grave,tp,LOCATION_GRAVE,0,nil)
		local res2=Duel.IsExistingMatchingCard(s.ffilter_grave,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2)
		
		return res1 or res2
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsOnField,nil)
	local mg1_opp=Duel.GetFusionMaterial(1-tp):Filter(Card.IsOnField,nil)
	mg1:Merge(mg1_opp)
	local b1=Duel.IsExistingMatchingCard(s.ffilter_field,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1)
	
	local mg2=Duel.GetMatchingGroup(s.matfilter_grave,tp,LOCATION_GRAVE,0,nil)
	local b2=Duel.IsExistingMatchingCard(s.ffilter_grave,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2)
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,4),aux.Stringid(id,5))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end
	
	if op==0 then
		-- 필드 융합
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.ffilter_field,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg1)
		local tc=sg:GetFirst()
		if not tc then return end
		
		tc:SetMaterial(nil)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg1,nil,tp)
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	else
		-- 묘지 덱 융합
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.ffilter_grave,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg2)
		local tc=sg:GetFirst()
		if not tc then return end
		
		-- 3장까지만 선택 가능하도록 필터링 (사실상 파괴수 몬스터 중 융합 소재를 고르는 것)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg2,nil,tp)
		if #mat>3 then
			-- 만약 소재가 4장 이상이면 3장까지만 허용하므로 경고 후 리턴 (보통 카기도라 소재가 3장 이하라면 문제없음)
			Duel.Hint(HINT_MSG,tp,STRING_INVALID_SELECTION) 
			return
		end
		
		tc:SetMaterial(mat)
		Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end