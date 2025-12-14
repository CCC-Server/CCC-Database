-- 대해의 제압 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- 속공 마법: 발동 제한
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 발동 조건: 자신 필드에 드래곤족 듀얼 몬스터 존재
function s.cfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 대상 지정
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

-- 파괴 + 조건부 무효화
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.Destroy(tc,REASON_EFFECT)~=0 then
			-- 추가 조건: 한 번 더 소환된(듀얼 상태) 몬스터 존재 시
			if Duel.IsExistingMatchingCard(s.gemini_filter,tp,LOCATION_MZONE,0,1,nil) then
				Duel.BreakEffect()
				-- 파괴된 카드가 여전히 필드에 남아있거나 무효화 가능한 경우에만
				if tc:IsFaceup() and not tc:IsDisabled() then
					Duel.NegateRelatedChain(tc,RESET_TURN_SET)
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_DISABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
					local e2=e1:Clone()
					e2:SetCode(EFFECT_DISABLE_EFFECT)
					tc:RegisterEffect(e2)
				end
			end
		end
	end
end

-- 필드에 한 번 더 소환된 듀얼 상태 몬스터 존재 확인
function s.gemini_filter(c)
	return c:IsFaceup() and c:IsType(TYPE_GEMINI) and c:IsGeminiState()
end
