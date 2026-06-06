--구혼성 쇄함루
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 레벨 9 몬스터 × 2장 이상 (ⓐ 반영)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,aux.FilterBoolFunctionParam(Card.IsXyzLevel,9),2,99)
	
	--①: 카드가 묘지로 보내졌을 경우에 발동할 수 있다 (동일 체인 위 1번까지)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.con1)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	
	--②: 이 카드가 묘지에 보내졌을 경우에 발동할 수 있다 (어디서든 가능, 1턴에 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end

-- ①번 효과 조건: 동일한 체인 위에서 이 효과가 아직 발동되지 않았는지 체크
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentChain()==0 or not exec_hint_check and not e:GetHandler():IsHasSetHint(id)
end

-- ①번 효과 소재 보충 대상 필터 (이 카드의 수비력 이하를 가진 자신 필드의 엑시즈 몬스터)
function s.xyzfilter(c,def)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:HasDefense() and c:GetDefense()<=def
end

function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- 이 카드가 필드에 앞면 표시로 존재하고 정상적인 수비력을 가질 때 판정 (자기 자신도 충족)
	if chk==0 then
		if not c:IsFaceup() or not c:HasDefense() then return false end
		local def=c:GetDefense()
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,def)
			and Duel.IsExistingMatchingCard(Card.IsCanOverlay,tp,LOCATION_GRAVE+LOCATION_REMOVED,LOCATION_GRAVE+LOCATION_REMOVED,1,nil,tp)
	end
	-- 동일 체인 위 1번 제한용 힌트 플래그 세팅
	e:GetHandler():RegisterSetHint(id)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() or not c:HasDefense() then return end
	local def=c:GetDefense()
	
	-- 1. 조건에 맞는 엑시즈 몬스터 선택 (수비력 이하)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local xyzg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,def)
	local sc=xyzg:GetFirst()
	if sc then
		Duel.HintSelection(xyzg)
		-- 2. 자신/상대 묘지(및 제외)에서 엑시즈 소재로 만들 카드 1장 선택
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local matg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsCanOverlay),tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,tp)
		local tc=matg:GetFirst()
		if tc then
			-- 3. 겹쳐서 소재로 하고 공/수 900 올리기
			Duel.Overlay(sc,tc)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(900)
			sc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			sc:RegisterEffect(e2)
		end
	end
end

-- ②번 효과 파괴 필터 (공격력 또는 수비력이 3000 이상인 필드의 몬스터)
function s.desfilter(c)
	return c:IsFaceup() and ((c:HasAttack() and c:GetAttack()>=3000) or (c:HasDefense() and c:GetDefense()>=3000))
end

function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end