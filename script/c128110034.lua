-- 광성파괴수 스페이스 도고란
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터 ID
function s.initial_effect(c)
	-- 파괴수 공통 제약 (③)
	c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsSetCard,0xd3),LOCATION_MZONE)
	
	-- 파괴수 공통 특수 소환 룰 (①, ②)
	-- ①: 상대 필드 몬스터 릴리스 후 상대 필드 특수 소환
	-- ②: 상대 필드에 파괴수 존재 시 패에서 특수 소환
	local e1,e2=aux.AddKaijuProcedure(c)
	
	-- ④: 파괴 효과 무효, 상대 몬스터 묘지로, 카운터 놓기
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_TOGRAVE+CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end
s.listed_series={0xd3} -- 파괴수
s.counter_list={COUNTER_KAIJU} -- 파괴수 카운터 사용

-- ④ 효과: 조건 (파괴를 포함하는 효과 발동 시)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- re:IsHasCategory(CATEGORY_DESTROY)로 파괴 효과 포함 여부 확인
	return re:IsHasCategory(CATEGORY_DESTROY) and Duel.IsChainNegatable(ev)
end

-- ④ 효과: 코스트 (카운터 2개 제거)
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,1,1,COUNTER_KAIJU,2,REASON_COST) end
	Duel.RemoveCounter(tp,1,1,COUNTER_KAIJU,2,REASON_COST)
end

-- ④ 효과: 타겟 (무효화 -> 묘지 송부)
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		-- 무효로 하고 '상대 필드의 몬스터를 전부' 보내야 하므로, 상대 몬스터가 1장 이상 있어야 발동 가능
		return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,1,0,COUNTER_KAIJU)
end

-- ④ 효과: 처리
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. 발동 무효
	if Duel.NegateActivation(ev) then
		-- 2. 상대 몬스터 전부 묘지로
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
		if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
			-- 3. 이 카드에 카운터 1개 놓기
			-- 묘지로 보낸 후 처리이므로, 이 카드가 여전히 필드에 앞면으로 존재해야 함
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				Duel.BreakEffect()
				c:AddCounter(COUNTER_KAIJU,1)
			end
		end
	end
end