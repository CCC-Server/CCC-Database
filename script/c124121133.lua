-- 고티스 트랩
local s,id=GetID()
function s.initial_effect(c)
	-- 패 발동 조건
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	-- ①: 덱 제외 (각기 다른 이름) 후 패/제외 존 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ②: 덱에서 공격력 0 이외의 어류족 제외 후 공격력 증가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.atkcost)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

-- "고티스" 카드군 코드 (0x18b)
s.set_ghoti=0x18b

-- [패 발동 조건]
function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
end

-- [① 덱 제외 필터]
function s.rmfilter(c)
	return c:IsSetCard(s.set_ghoti) and c:IsLevelBelow(4) and c:IsAbleToRemove()
end

-- [① 특수 소환 필터] 패 또는 앞면 제외 상태
function s.spfilter(c,e,tp)
	-- 제외 존일 경우 앞면 표시여야 함 (패는 뒷면 구분이 없으므로 패스)
	if c:IsLocation(LOCATION_REMOVED) and not c:IsFaceup() then return false end
	return c:IsRace(RACE_FISH) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- [① 타겟 지정]
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_REMOVED)
end

-- [① 효과 처리] aux.dncheck(동명 카드 중복 금지) 로직 적용
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	if ct==0 then return end
	
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_DECK,0,nil)
	if #g==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	-- aux.dncheck를 사용해 상대 몬스터 수(ct)까지 각각 다른 이름으로 고르도록 통제
	local tg=aux.SelectUnselectGroup(g,e,tp,1,ct,aux.dncheck,1,tp,HINTMSG_REMOVE)
	
	if #tg>0 and Duel.Remove(tg,POS_FACEUP,REASON_EFFECT)>0 then
		-- 그 후, 패/제외 존의 어류족 체크
		local sg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND|LOCATION_REMOVED,0,nil,e,tp)
		if #sg>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local ssg=sg:Select(tp,1,1,nil)
			Duel.SpecialSummon(ssg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- [② 코스트 필터] 공격력 0 이외 한정
function s.costfilter(c)
	return c:IsRace(RACE_FISH) and not c:IsAttack(0) and c:IsAbleToRemoveAsCost()
end

-- [② 코스트 지불 및 공격력 저장]
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and Duel.Remove(tc,POS_FACEUP,REASON_COST)>0 then
		local atk=tc:GetTextAttack()
		if atk<0 then atk=0 end
		e:SetLabel(atk)
	end
end

-- [② 타겟 지정 (발동 검증 용)]
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil) end
end

-- [② 효과 처리]
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local atk=e:GetLabel()
	if atk<=0 then return end
	
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetValue(atk)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end