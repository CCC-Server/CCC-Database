local s,id=GetID()
function s.initial_effect(c)
	--발동 시 효과 선택
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--세트한 턴에 발동 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCondition(s.actcon)
	c:RegisterEffect(e2)
	
	--세트한 턴 발동 시의 릴리스 코스트 처리
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(id) -- 커스텀 플래그용
	c:RegisterEffect(e3)
end

s.listed_names={24857466} -- 명왕룡 반달기온

-- 세트한 턴 발동 조건: 반달기온 또는 기재 몬스터 릴리스 가능 여부
function s.actfilter(c)
	return c:IsFaceup() and (c:IsCode(24857466) or c:ListsCode(24857466)) and c:IsReleasable()
end
function s.actcon(e)
	return Duel.IsExistingMatchingCard(s.actfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- 효과 1: 덱에서 카운터 함정 세트 필터
function s.setfilter(c)
	return c:IsType(TYPE_COUNTER) and c:ListsCode(24857466) and c:IsSSetable()
end

-- 전체 발동 조건
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- 효과 2(무효)를 위한 체크: 몬스터 효과 발동 여부
	local res2 = re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
	-- 효과 1(세트)은 언제나 가능 (자신 턴/상대 턴 체인 발생 시 등)
	-- 여기서는 카운터 함정 특성상 체인 발생 시에만 발동 가능하도록 함정 기본 규칙을 따름
	return true
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
	if chk==0 then return b1 or b2 end
	
	-- 세트한 턴 발동 시 코스트 지불
	if e:GetHandler():IsStatus(STATUS_SET_TURN) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local g=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_MZONE,0,1,1,nil)
		Duel.Release(g,REASON_COST)
	end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
	end
	e:SetLabel(op)
	
	if op==0 then
		e:SetCategory(0)
		e:SetProperty(0)
	else
		e:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
		e:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
		Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
		if re:GetHandler():IsRelateToEffect(re) then
			Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
		end
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		-- ● "명왕룡 반달기온"의 카드명이 쓰여진 카운터 함정 1장을 덱에서 세트
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SSet(tp,g:GetFirst())
		end
	else
		-- ● 몬스터의 효과 발동 무효 및 파괴
		if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
			Duel.Destroy(eg,REASON_EFFECT)
		end
	end
end