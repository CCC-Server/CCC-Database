--G.Rock 레이드
local s,id=GetID()
function s.initial_effect(c)
	-- 카드 발동
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	
	-- ①: 상대 패 / 필드 몬스터 효과 발동 시 무효 및 소재화
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL+EFFECT_FLAG_CARD_TARGET)
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.con2)
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
	
	-- ②: 이 카드가 묘지로 보내졌을 경우
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.cost3)
	e3:SetTarget(s.tar3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)
end

-- ① 효과 관련 함수
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsMonsterEffect() or not Duel.IsChainNegatable(ev) then return false end
	local rc=re:GetHandler()
	-- [천위의 용귀신 체크 반영] 발동한 카드 정보가 체인 발동 시점과 여전히 일치하는가 (위치 이동이 없었는가)
	if not rc:IsRelateToEffect(re) then return false end
	
	-- 효과가 발동한 당시의 장소가 패(HAND) 또는 필드 몬스터 존(MZONE)인지 최종 검증
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return (loc&LOCATION_HAND)~=0 or (loc&LOCATION_MZONE)~=0
end
function s.tfil2(c)
	return c:IsFaceup() and c:IsSetCard(0xfa6) and c:IsType(TYPE_XYZ)
end
function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.tfil2(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tfil2,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tfil2,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	-- 대상 엑시즈가 필드에 앞면으로 존재하고 효과 내성이 없으며, 상대 몬스터가 여전히 유효한 연동 상태일 때
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsImmuneToEffect(e) and rc:IsRelateToEffect(re) then
		-- 1. 패 / 필드의 그 몬스터를 대상 몬스터의 엑시즈 소재로 만든다
		Duel.Overlay(tc,rc,true)
		
		-- 2. 소재로 들어갔음이 완벽히 연산 완료되었다면, 그 발동한 효과를 무효로 한다
		local og=tc:GetOverlayGroup()
		if og:IsContains(rc) then
			Duel.NegateActivation(ev)
		end
	end
end

-- ② 효과 관련 함수
function s.cost3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckRemoveOverlayCard(tp,1,0,1,REASON_COST)
	end
	Duel.RemoveOverlayCard(tp,1,0,1,1,REASON_COST)
end
function s.tar3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return true
	end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end
function s.op3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end