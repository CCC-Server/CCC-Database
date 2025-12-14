--스펠크래프트의 주문 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--속공 마법 발동
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_COUNTER+CATEGORY_RECOVER+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E) -- 속공 마법용 타이밍 힌트
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--"스펠크래프트 마녀의 가마솥" 코드
s.cauldrontg=128770286

--①: 이하의 효과 중 1개 선택
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local b1=s.addcounter_costcheck(tp)
	local b2=true
	local b3=s.removect_check(tp)

	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)}, -- ● 자신 필드의 "스펠크래프트 마녀의 가마솥"에 마력 카운터 4개 올리기
		{b2,aux.Stringid(id,1)}, -- ● 자신은 1000 LP 회복
		{b3,aux.Stringid(id,2)}  -- ● 가마솥의 마력 카운터 4개 제거 → 상대 필드의 공격력 1500 이하 몬스터 전부 파괴
	)

	if op==1 then
		s.addcounter_op(e,tp)
	elseif op==2 then
		Duel.Recover(tp,1000,REASON_EFFECT)
	elseif op==3 then
		s.removect_op(e,tp)
	end
end

--①-1: 가마솥에 카운터 4개 올리기
function s.cauldronfilter(c)
	return c:IsFaceup() and c:IsCode(s.cauldrontg)
end
function s.addcounter_costcheck(tp)
	return Duel.IsExistingMatchingCard(s.cauldronfilter,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.addcounter_op(e,tp)
	local tc=Duel.SelectMatchingCard(tp,s.cauldronfilter,tp,LOCATION_ONFIELD,0,1,1,nil):GetFirst()
	if tc then
		tc:AddCounter(COUNTER_SPELL,4)
	end
end

--①-3: 카운터 4개 제거 후 파괴
function s.removect_check(tp)
	local tc=Duel.GetFirstMatchingCard(s.cauldronfilter,tp,LOCATION_ONFIELD,0,nil)
	return tc and tc:IsCanRemoveCounter(tp,COUNTER_SPELL,4,REASON_COST)
end
function s.removect_op(e,tp)
	local tc=Duel.GetFirstMatchingCard(s.cauldronfilter,tp,LOCATION_ONFIELD,0,nil)
	if tc and tc:RemoveCounter(tp,COUNTER_SPELL,4,REASON_COST)>0 then
		local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end

--공격력 1500 이하 파괴 필터
function s.desfilter(c)
	return c:IsFaceup() and c:GetAttack()<=1500
end
