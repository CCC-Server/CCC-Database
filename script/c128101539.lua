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
end

s.listed_names={24857466} -- 명왕룡 반달기온

-- 세트한 턴 발동 조건: 반달기온 또는 기재 몬스터 릴리스 가능 여부
function s.actfilter(c)
	return c:IsFaceup() and (c:IsCode(24857466) or c:ListsCode(24857466)) and c:IsReleasable()
end
function s.actcon(e)
	return Duel.IsExistingMatchingCard(s.actfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- 효과 1: 특수 소환 대상 필터
function s.spfilter(c,e,tp)
	return (c:IsCode(24857466) or c:ListsCode(24857466)) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- 카운터 함정이므로 기본적으로 체인 발생 시 발동
	return true
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 효과 1: 덱/묘지 특수 소환 가능 여부
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	-- 효과 2: 상대의 마법/함정 발동 무효 가능 여부 (상대가 발동했을 때만)
	local b2=rp~=tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) 
		and (re:IsActiveType(TYPE_SPELL) or re:IsActiveType(TYPE_TRAP))
		and Duel.IsChainNegatable(ev)
	
	if chk==0 then return b1 or b2 end
	
	-- 세트한 턴 발동 시 릴리스 코스트 처리
	if e:GetHandler():IsStatus(STATUS_SET_TURN) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local g=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_MZONE,0,1,1,nil)
		Duel.Release(g,REASON_COST)
	end
	
	-- 효과 선택
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
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	else
		e:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
		Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
		if re:GetHandler():IsRelateToEffect(re) then
			Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
		end
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		-- ● 덱 / 묘지에서 특수 소환
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	else
		-- ● 마법 / 함정 무효 및 제외
		if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
			Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
		end
	end
end