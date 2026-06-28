--구혼성 쇄함루
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 레벨 9 몬스터 × 2장
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,9,2)
	
	--①: 카드가 묘지로 보내졌을 경우에 발동할 수 있다 (동일 체인 위 1번까지)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_MZONE)
	-- "크샤트리라 어라이즈하트"의 체인 플래그 연동을 위해 cost 함수 등록
	e1:SetCost(s.cost1)
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

-- 동일 체인 위에서 1번만 발동할 수 있도록 제약하는 코스트 함수 (어라이즈하트 방식)
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetFlagEffect(id)==0 end
	c:RegisterFlagEffect(id,RESET_CHAIN,0,1)
end

-- ①번 효과 소재 보충 대상 필터 (이 카드의 수비력 이하를 가진 자신 필드의 엑시즈 몬스터)
function s.xyzfilter(c,def)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:HasDefense() and c:GetDefense()<=def
end

-- 묘지의 카드가 해당 엑시즈 몬스터의 소재가 될 수 있는지 검증하는 필터
function s.matcheck(c,g,tp,e)
	return g:IsExists(function(xc) return c:IsCanBeXyzMaterial(xc,tp,REASON_EFFECT) end,1,nil)
end

function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if not c:IsFaceup() or not c:HasDefense() then return false end
		local def=c:GetDefense()
		local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil,def)
		if #xyzg==0 then return false end
		return Duel.IsExistingMatchingCard(s.matcheck,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,xyzg,tp,e)
	end
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() or not c:HasDefense() then return end
	local def=c:GetDefense()
	
	-- 1. 조건에 맞는 엑시즈 몬스터 그룹 확보 (수비력 이하)
	local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil,def)
	if #xyzg==0 then return end
	
	-- 2. 자신/상대 묘지에서 엑시즈 소재로 만들 카드 1장 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local matg=Duel.SelectMatchingCard(tp,s.matcheck,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,xyzg,tp,e)
	local tc=matg:GetFirst()
	if tc then
		-- 3. 고른 묘지의 카드를 소재로 삼을 수 있는 엑시즈 몬스터를 그룹에서 다시 필터링하여 1장 최종 선택
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local scg=xyzg:FilterSelect(tp,function(xc) return tc:IsCanBeXyzMaterial(xc,tp,REASON_EFFECT) and not tc:IsImmuneToEffect(e) end,1,1,nil)
		local sc=scg:GetFirst()
		if sc then
			Duel.HintSelection(scg)
			tc:CancelToGrave()
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

-- ②번 효과 파괴 필터: "링크 파티" 규격 기반 수정 적용
-- 공격력 3000 이상(IsAttackAbove) 또는 수비력 3000 이상(IsDefenseAbove)인 필드의 앞면 표시 몬스터
function s.desfilter(c)
	return c:IsFaceup() and (c:IsAttackAbove(3000) or c:IsDefenseAbove(3000))
end

-- 타겟 구역을 0, LOCATION_MZONE(상대)에서 LOCATION_MZONE, LOCATION_MZONE(자신/상대 전체)으로 확장
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