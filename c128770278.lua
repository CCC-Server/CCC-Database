--스펠크래프트 타임마스터 (예시)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- E1 : 소환 제한
	------------------------------------
	c:EnableReviveLimit()
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	
	------------------------------------
	-- E2 : 스펠크래프트 효과로 특수 소환 시 카운트 시작
	------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	------------------------------------
	-- E3 : 턴 카운트 및 효과 발동 (양쪽 턴마다 진행)
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PHASE_START+PHASE_STANDBY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.turnop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------------
-- E1 : "스펠크래프트 오버디멘션"으로만 특수 소환 가능
-----------------------------------------------------------
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsCode(128770291)  -- "스펠크래프트 오버디멘션"의 실제 코드로 변경
end

-----------------------------------------------------------
-- E2 : 스펠크래프트 카드 효과로 소환된 경우 카운트 시작
-----------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler():IsSetCard(0x761) -- "스펠크래프트" 시리즈 코드 (예시)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	c:SetTurnCounter(1) -- 소환 턴을 1턴째로 시작
	Duel.Hint(HINT_CARD,0,id)
end

-----------------------------------------------------------
-- E3 : 턴 카운트 + 효과 적용 (2~6턴차)
-----------------------------------------------------------
function s.turnop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() or not c:IsSummonType(SUMMON_TYPE_SPECIAL) then return end
	local ct=c:GetTurnCounter()
	if ct==0 then return end

	-- 양쪽 턴 스탠바이마다 카운트 증가
	c:SetTurnCounter(ct+1)
	local t=ct+1
	Duel.Hint(HINT_CARD,0,id) -- 표시용

	------------------------------------
	-- 2턴째 : 스펠크래프트 몬스터 ATK 5000
	------------------------------------
	if t==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectMatchingCard(tp,s.scfilter,tp,LOCATION_MZONE,0,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(5000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			Duel.Hint(HINT_CARD,0,id)
		end
	end

	------------------------------------
	-- 3턴째 : 상대 필드 전멸 + 2000 데미지
	------------------------------------
	if t==3 then
		local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
		if #g>0 then Duel.Destroy(g,REASON_EFFECT) end
		Duel.Damage(1-tp,2000,REASON_EFFECT)
		Duel.Hint(HINT_CARD,0,id)
	end

	------------------------------------
	-- 4턴째 : 스펠크래프트 몬스터 전원 직접 공격 허용
	------------------------------------
	if t==4 then
		local g=Duel.GetMatchingGroup(s.scfilter,tp,LOCATION_MZONE,0,nil)
		for tc in g:Iter() do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DIRECT_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
		Duel.Hint(HINT_CARD,0,id)
	end

	------------------------------------
	-- 5턴째 : 상대 LP 100
	------------------------------------
	if t==5 then
		Duel.SetLP(1-tp,100)
		Duel.Hint(HINT_CARD,0,id)
	end

	------------------------------------
	-- 6턴째 : 듀얼 승리
	------------------------------------
	if t==6 then
			Duel.Hint(HINT_CARD,0,id)
	Duel.Win(tp,0x60) 
	end
end

-----------------------------------------------------------
-- 스펠크래프트 몬스터 필터
-----------------------------------------------------------
function s.scfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x761)
end

