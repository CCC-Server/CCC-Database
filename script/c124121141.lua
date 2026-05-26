-- 환홍현신 살라무리아
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 발동 후 효과 몬스터가 되어 특수 소환 (클리포트 다운 e1 구조 완전 이식)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ②: 제외되었을 경우 또는 자신의 효과로 묘지에 보내졌을 경우
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- ②번 효과 1턴에 1번 제한
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_REMOVE)
	e3:SetCondition(s.thcon_rm)
	c:RegisterEffect(e3)
end

-- "환홍" 카드군 지정 코드
s.set_phanred=0xfa8

-- [①번 타겟 검증] 클리포트 다운의 구조를 그대로 사용 (살라무리아 스탯 반영)
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and e:IsHasType(EFFECT_TYPE_ACTIVATE) 
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,TYPE_MONSTER|TYPE_EFFECT,0,0,4,RACE_FIEND,ATTRIBUTE_FIRE) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

-- [①번 효과 처리] 클리포트 다운 소환 + 버제스토마식 제외 구조 안착
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,TYPE_MONSTER|TYPE_EFFECT,0,0,4,RACE_FIEND,ATTRIBUTE_FIRE) then
		
		-- 클리포트 다운 공식 수식: TYPE_EFFECT만 주입하여 함정 판정을 완전히 탈피시킵니다.
		c:AddMonsterAttribute(TYPE_EFFECT)
		
		-- 앞면 표시 소환 스텝 진행
		if Duel.SpecialSummonStep(c,0,tp,tp,true,false,POS_FACEUP) then
			c:AddMonsterAttributeComplete()
			
			-- [복구] 버제스토마식 리다이렉트 제외 효과 강제 주입
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(3300) -- "필드에서 벗어났을 경우에 제외된다" 시스템 힌트
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
			e1:SetReset(RESET_EVENT|RESETS_REDIRECT)
			e1:SetValue(LOCATION_REMOVED)
			c:RegisterEffect(e1,true)
		end
	end
	-- 최종 완료 선언 매립
	Duel.SpecialSummonComplete()
end

-- ②번 효과 발동 조건 (자신의 효과로 묘지에 보내졌을 경우)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT) and rp==tp
end

-- ②번 효과 발동 조건 (제외되었을 경우)
function s.thcon_rm(e,tp,eg,ep,ev,re,r,rp)
	return true
end

-- 서치 필터 (동명 카드인 살라무리아를 제외한 "환홍" 카드)
function s.thfilter(c)
	return c:IsSetCard(s.set_phanred) and not c:IsCode(id) and c:IsAbleToHand()
end

-- ②번 효과 타겟 지정
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

-- ②번 효과 처리 (덱에서 "환홍" 서치 후 패 1장 버리기)
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
			Duel.ConfirmCards(1-tp,g)
			Duel.BreakEffect()
			
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
			Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
		end
	end
end