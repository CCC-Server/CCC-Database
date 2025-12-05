--오리카: 오버 리밋 하데스 차저
local s,id=GetID()
function s.initial_effect(c)
	--①: 리미터 해제 발동 시 또는 배수 공격력 존재 시 특소 + 파괴 (체인 발동)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1) -- 리미터 해제 발동에 체인
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--①: (프리 체인 발동)
	local e2=e1:Clone()
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e2:SetCondition(s.spcon2) -- 배수 공격력 몬스터 존재 확인
	c:RegisterEffect(e2)

	--②: 공 2100 증가 + 리미터 해제 세트
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetHintTiming(TIMING_DAMAGE_STEP)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	--③: 공격력 배수일 때 효과 파괴 내성
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.indcon)
	e4:SetValue(1)
	c:RegisterEffect(e4)
end

-- "리미터 해제" ID
local CARD_LIMITER_REMOVAL = 23171610

-------------------------------------------------------------------------
-- ① 효과 구현
-------------------------------------------------------------------------
-- 조건 1: "리미터 해제"가 발동했을 경우
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler():IsCode(CARD_LIMITER_REMOVAL)
end

-- 조건 2: 필드에 공격력 배수 몬스터가 존재할 경우
function s.dbl_filter(c)
	return c:IsFaceup() and c:GetBaseAttack()>0 and c:GetAttack() >= c:GetBaseAttack()*2
end
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.dbl_filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,0,0) -- 자신 1장, 상대 1장 파괴
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. 특수 소환
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 기계족 제약 (잔존 효과)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

		-- 2. 파괴 처리 (비대상)
		-- 자신 필드 몬스터 선택
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g1=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,nil)
		if #g1>0 then
			Duel.HintSelection(g1)
			local my_mon=g1:GetFirst()
			local atk=my_mon:GetAttack()
			
			-- 그 공격력 이하의 상대 몬스터 선택
			local g2=Duel.GetMatchingGroup(function(c,val) return c:GetAttack()<=val end,tp,0,LOCATION_MZONE,nil,atk)
			if #g2>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
				local sg2=g2:Select(tp,1,1,nil)
				Duel.HintSelection(sg2)
				g1:Merge(sg2)
				Duel.BreakEffect()
				Duel.Destroy(g1,REASON_EFFECT)
			end
		end
	end
end

function s.splimit(e,c)
	return not c:IsRace(RACE_MACHINE)
end

-------------------------------------------------------------------------
-- ② 효과 구현
-------------------------------------------------------------------------
function s.setfilter(c)
	return c:IsCode(CARD_LIMITER_REMOVAL) and c:IsSSetable()
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 공격력 2100 증가 (이 카드만)
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(2100)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
	
	-- 묘지의 리미터 해제 세트
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.setfilter),tp,LOCATION_GRAVE,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local sg=g:Select(tp,1,1,nil)
		local tc=sg:GetFirst()
		if tc then
			Duel.SSet(tp,tc)
			-- 세트한 턴 발동 가능
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
			e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end

-------------------------------------------------------------------------
-- ③ 효과 구현
-------------------------------------------------------------------------
function s.indcon(e)
	local c=e:GetHandler()
	return c:GetAttack() >= c:GetBaseAttack()*2
end