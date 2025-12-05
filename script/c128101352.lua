--오리카: 오버 리밋 트랜스암 부스터
local s,id=GetID()
function s.initial_effect(c)
	--①: 룰 특수 소환 (패 / 묘지)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- 소환 자체를 1턴에 1번 제약
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--②: 소환 성공 시 서치 + (조건부) 공배수 & 자괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1}) -- ②효과 명칭 제약
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
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

-- 기계족 소환 카운터 체크용 (②효과 제약)
function s.splimit_filter(c)
	return not c:IsRace(RACE_MACHINE)
end
function s.initial_effect_global(c,mode)
	if mode==1 then
		-- 이 턴 기계족 이외의 특수 소환 횟수를 체크하는 카운터 생성
		Duel.AddCustomActivityCounter(id,ACTIVITY_SPSUMMON,s.splimit_filter)
	end
end

-- "리미터 해제" ID
local CARD_LIMITER_REMOVAL = 23171610

-------------------------------------------------------------------------
-- ① 효과: 패/묘지 특수 소환
-------------------------------------------------------------------------
function s.atkfilter(c)
	return c:IsFaceup() and c:GetAttack() >= c:GetBaseAttack()*2
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- 필드에 원래 공격력의 배 이상인 몬스터가 존재하고, 소환 공간이 있어야 함
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.atkfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

-------------------------------------------------------------------------
-- ② 효과: 서치 + 리미터 해제 2장 이상일 시 공뻥
-------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc48) and c:IsMonster() and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 맹세 효과: 이 턴에 이미 기계족 이외의 몬스터를 특수 소환했다면 발동 불가
		if Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)>0 then return false end
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	-- 제약 설명 (클라이언트 힌트)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return not c:IsRace(RACE_MACHINE) end)
	Duel.RegisterEffect(e1,tp)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- 기계족 이외 특수 소환 불가 제약 적용 (맹세 효과 처리)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return not c:IsRace(RACE_MACHINE) end)
	Duel.RegisterEffect(e1,tp)

	-- 서치 처리
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)

			-- 추가 효과: 묘지에 "리미터 해제" 2장 이상 확인
			local lc=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsCode,CARD_LIMITER_REMOVAL),tp,LOCATION_GRAVE,0,nil)
			local mg=Duel.GetMatchingGroup(Card.IsRace,tp,LOCATION_MZONE,0,nil,RACE_MACHINE)
			
			if lc>=2 and #mg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
				local sg=mg:Select(tp,1,1,nil)
				local tc=sg:GetFirst()
				if tc then
					-- 공격력 2배
					local e2=Effect.CreateEffect(e:GetHandler())
					e2:SetType(EFFECT_TYPE_SINGLE)
					e2:SetCode(EFFECT_SET_ATTACK_FINAL)
					e2:SetValue(tc:GetAttack()*2)
					e2:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e2)

					-- 턴 종료시 파괴 예약
					local e3=Effect.CreateEffect(e:GetHandler())
					e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
					e3:SetCode(EVENT_PHASE+PHASE_END)
					e3:SetCountLimit(1)
					e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
					e3:SetLabelObject(tc)
					e3:SetCondition(s.descon)
					e3:SetOperation(s.desop)
					e3:SetReset(RESET_PHASE+PHASE_END)
					Duel.RegisterEffect(e3,tp)
					tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1) -- 파괴 대상 식별용
				end
			end
		end
	end
end

-- 엔드 페이즈 파괴 처리
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return tc:GetFlagEffect(id)~=0
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Destroy(tc,REASON_EFFECT)
end

-------------------------------------------------------------------------
-- ③ 효과: 공격력 2배 이상 시 효과 파괴 내성
-------------------------------------------------------------------------
function s.indcon(e)
	local c=e:GetHandler()
	return c:GetAttack() >= c:GetBaseAttack()*2
end