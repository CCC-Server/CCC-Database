--오리카: 오버 리밋 부스터 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--①: 릴리스하고 발동. 덱/묘지 특소 + 리미터 해제 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O) -- 상대 턴 발동 가능
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCountLimit(1,id)
	e1:SetCost(aux.bfgcost) -- 이 카드를 릴리스하고 (제외가 아니라 릴리스면 e:GetHandler():Release() 사용해야 함. 아래 수정)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: 리미터 해제 발동 시 소생 + 싱크로/융합
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SPECIAL_SUMMON) -- 소생 후 엑스트라 소환
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.sccon)
	e2:SetTarget(s.sctg)
	e2:SetOperation(s.scop)
	c:RegisterEffect(e2)

	--③: 공격력 배수일 때 효과 파괴 내성
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.indcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
end

-- "리미터 해제" ID
local CARD_LIMITER_REMOVAL = 23171610

-------------------------------------------------------------------------
-- ① 효과 구현
-------------------------------------------------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc48) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.setfilter(c)
	return c:IsCode(CARD_LIMITER_REMOVAL) and c:IsSSetable()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 묘지의 리미터 해제 확인
		local lg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.setfilter),tp,LOCATION_GRAVE,0,nil)
		if #lg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sg=lg:Select(tp,1,1,nil)
			local tc=sg:GetFirst()
			if tc then
				Duel.SSet(tp,tc)
				-- 세트한 턴에 발동 가능 (속공 마법용 코드)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
				e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end

-------------------------------------------------------------------------
-- ② 효과 구현 (소생 + 싱크로/융합)
-------------------------------------------------------------------------
function s.sccon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler():IsCode(CARD_LIMITER_REMOVAL)
end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA) -- 엑스트라 덱 특소 정보
end

-- 기계족 싱크로 필터
function s.synfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsSynchroSummonable(nil)
end
-- 기계족 융합 필터
function s.fusfilter(c,e,tp,m)
	return c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION) and c:CheckFusionMaterial(m,nil,tp)
end

function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. 이 카드를 특수 소환
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 기계족 제약 (잔존 효과)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetDescription(aux.Stringid(id,3))
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

		-- 2. 싱크로 또는 융합 소환 실행
		-- 필드의 몬스터를 소재로 해야 함
		local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
		
		local b1=Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil)
		local b2=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)

		if (b1 or b2) and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			local op=0
			if b1 and b2 then op=Duel.SelectOption(tp,aux.Stringid(id,5),aux.Stringid(id,6))
			elseif b1 then op=0
			else op=1 end

			if op==0 then
				-- 싱크로 소환
				local sg=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil)
				local sc=sg:GetFirst()
				if sc then
					Duel.SynchroSummon(tp,sc,nil)
				end
			else
				-- 융합 소환
				local fg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
				local fc=fg:GetFirst()
				if fc then
					fc:SetMaterial(mg)
					Duel.SendtoGrave(mg,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
					Duel.BreakEffect()
					Duel.GameCheckTurn() -- 융합 소환 처리 안전장치
					Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
					fc:CompleteProcedure()
				end
			end
		end
	end
end

function s.splimit(e,c)
	return not c:IsRace(RACE_MACHINE)
end

-------------------------------------------------------------------------
-- ③ 효과 구현
-------------------------------------------------------------------------
function s.indcon(e)
	local c=e:GetHandler()
	return c:GetAttack() >= c:GetBaseAttack()*2
end