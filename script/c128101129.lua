-- 운마물-수퍼셀
local s,id=GetID()
function s.initial_effect(c)
	-- link summon
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x18),2,99) -- "운마물" 몬스터 2장 이상
	c:EnableReviveLimit()

	-- Effect 1: 링크 소환 시 덱/엑스트라 덱에서 "운마물" 몬스터를 묘지로 보내고, 물 속성만 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.gyop)
	c:RegisterEffect(e1)

	-- Effect 2: 효과 무효화하고 포그 카운터를 놓는 효과 (상대 턴, 묘지에서 제외)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.counter_condition) -- 효과 발동 조건
	e2:SetCost(s.counter_cost) -- 코스트 설정
	e2:SetTarget(s.counter_target) -- 타겟 설정
	e2:SetOperation(s.counter_operation) -- 효과 실행
	c:RegisterEffect(e2)
end
s.listed_series={0x18}

function s.gyfilter(c)
	return c:IsSetCard(0x18) and c:IsAbleToGrave()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 덱/엑스트라 덱에서 "운마물" 몬스터를 묘지로 보냄
	local tc=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil):GetFirst()
	if tc and Duel.SendtoGrave(tc,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_GRAVE) then
		-- Effect 1 완료 후 추가 작업
		-- 물 속성 몬스터만 특수 소환할 수 있게 제한
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.summon_limit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- 물 속성 몬스터만 특수 소환할 수 있도록 제한하는 필터
function s.summon_limit(e,c,sump,sumtype,sumpos,targetp)
	return not c:IsAttribute(ATTRIBUTE_WATER)
end

-- Effect 2: 상대 턴에 발동되는 조건 (묘지에서 제외 후 발동)
function s.counter_condition(e,tp,eg,ep,ev,re,r,rp)
	return tp~=Duel.GetTurnPlayer() -- 상대 턴에 발동
end

-- Effect 2: 묘지에서 제외하는 코스트
function s.counter_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- Effect 2: 타겟 설정 (상대 필드의 앞면 표시 몬스터)
function s.counter_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

-- Effect 2: 몬스터의 효과를 무효화하고 포그 카운터를 3개 놓음
function s.counter_operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		-- 효과 무효화
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		-- 포그 카운터 3개 추가
		tc:AddCounter(0x1019,3)
	end
end
