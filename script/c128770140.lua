--하이랜드의 방위메카
local s,id=GetID()
function s.initial_effect(c)
	--① 메인 페이즈에 발동 / 덱패 카드명 전부 달라야 / 2개 효과 선택
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
s.listed_series={0x755}

---------------------------------------
--덱 / 패 카드명이 전부 다른지 판정
function s.deckhand_allunique(tp)
	local g=Duel.GetFieldGroup(tp,LOCATION_DECK+LOCATION_HAND,0)
	return g:GetClassCount(Card.GetCode)==#g
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() and s.deckhand_allunique(tp)
end

---------------------------------------
--선택지 타겟 (발동 직전에도 다시 체크)
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.deckhand_allunique(tp) end
end

---------------------------------------
--실행
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ops={
		aux.Stringid(id,1), --① 공격력 2배
		aux.Stringid(id,2), --② 다른 하이랜드 atk+1000
		aux.Stringid(id,3), --③ 대상 내성 + 전투 파괴
		aux.Stringid(id,4), --④ 토큰 소환
		aux.Stringid(id,5)  --⑤ 전투 파괴 내성 + 회복
	}

	-- 첫 번째 선택
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,6))
	local sel1=Duel.SelectOption(tp,table.unpack(ops))
	local choice1=sel1+1

	-- 두 번째 선택 (첫 번째 선택 제외)
	local ops2={}
	local map={}
	for i=1,#ops do
		if i~=choice1 then
			table.insert(ops2,ops[i])
			table.insert(map,i) -- 실제 인덱스 매핑
		end
	end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,7))
	local sel2=Duel.SelectOption(tp,table.unpack(ops2))
	local choice2=map[sel2+1]

	local choices={choice1,choice2}
	for _,choice in ipairs(choices) do
		if choice==1 then
			-- 공격 선언시 atk 2배
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
			e1:SetCode(EVENT_ATTACK_ANNOUNCE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
				local c=e:GetHandler()
				if c:IsRelateToEffect(e) and c:IsFaceup() then
					local atk=c:GetAttack()
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_SET_ATTACK_FINAL)
					e1:SetValue(atk*2)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE_CAL)
					c:RegisterEffect(e1)
				end
			end)
			c:RegisterEffect(e1)

		elseif choice==2 then
			-- 다른 하이랜드 atk+1000
			local g=Duel.GetMatchingGroup(function(tc) return tc:IsSetCard(0x755) and tc~=c end,tp,LOCATION_MZONE,0,nil)
			for tc in aux.Next(g) do
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(1000)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
			end

		elseif choice==3 then
			-- 내성 + 전투 파괴 효과
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
			e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
			e1:SetRange(LOCATION_MZONE)
			e1:SetValue(aux.tgoval)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)

			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
			e2:SetCode(EVENT_DAMAGE_STEP_END)
			e2:SetRange(LOCATION_MZONE)
			e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
				return c:GetBattleTarget()
			end)
			e2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
				local bc=c:GetBattleTarget()
				if bc and bc:IsRelateToBattle() then
					Duel.Destroy(bc,REASON_EFFECT)
				end
			end)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e2)

		elseif choice==4 then
			-- 토큰 소환
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsPlayerCanSpecialSummonMonster(tp,128770141,0x755,TYPES_TOKEN,c:GetAttack(),2000,8,RACE_MACHINE,ATTRIBUTE_DARK) then
				local token=Duel.CreateToken(tp,128770141)
				Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
			end

		elseif choice==5 then
			-- 전투 파괴 내성 + 회복
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)

			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
			e2:SetCode(EVENT_BATTLE_DESTROYING)
			e2:SetRange(LOCATION_MZONE)
			e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
				return eg:IsContains(c)
			end)
			e2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
				local bc=c:GetBattleTarget()
				if bc and bc:IsRelateToBattle() then
					Duel.Recover(tp,bc:GetAttack(),REASON_EFFECT)
				end
			end)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e2)
		end
	end
end


