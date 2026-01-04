-- 오버 스플래시 임팩트
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 발동 무효 및 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- 패에서 발동 가능
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
end
s.listed_names={36076683} -- No.73 격룡신 어비스 스플래시

-- [패 발동 조건]
function s.handfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and (c:IsCode(36076683) or c:ListsCode(36076683))
end
function s.handcon(e)
	return Duel.IsExistingMatchingCard(s.handfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- [효과 ① 관련 함수]
function s.cfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_WATER)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
		and (re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE))
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- tp를 인자로 받도록 수정
function s.remfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_WATER) and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT)
end
function s.desfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 무효하고 파괴
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) and Duel.Destroy(eg,REASON_EFFECT)~=0 then
		-- 추가 효과 처리 확인: tp를 인자로 전달
		local g_xyz=Duel.GetMatchingGroup(s.remfilter,tp,LOCATION_MZONE,0,nil,tp)
		local g_des=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
		
		if #g_xyz>0 and #g_des>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DEATTACHFROM)
			local sc=g_xyz:Select(tp,1,1,nil):GetFirst()
			if sc:RemoveOverlayCard(tp,1,1,REASON_EFFECT) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
				local dc=g_des:Select(tp,1,1,nil)
				if #dc>0 then
					Duel.Destroy(dc,REASON_EFFECT)
				end
			end
		end
	end
end