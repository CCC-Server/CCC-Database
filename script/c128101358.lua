--Over Limit - Dead Heat
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------
	-- 패에서 발동 가능
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	--------------------------------
	-- ① 이 카드명은 필드/묘지에서 "Limiter Removal" 취급
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	-- SET 상태에서도 코드 변환이 적용되도록 SET_AVAILABLE 추가
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_SET_AVAILABLE)
	e1:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(23171610) -- "Limiter Removal"
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 상대 필드에 몬스터가 특수 소환되었을 때 발동하는 함정 효과
	--   (노멀 함정이니까 ACTIVATE형 트리거로 구현해야 실제로 발동 가능)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	-- "You can only use the ② effect ... once per turn."
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- 리미터 해제
s.listed_names={23171610}
-- "Over Limit" 카드군
s.listed_series={0xc48}

--------------------------------
-- 패에서 발동 조건
-- If you control no face-up monsters, you can activate this card from your hand.
--------------------------------
function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	return not Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
end

--------------------------------
-- ② 조건: 상대 필드에 몬스터가 특수 소환되었을 때
--------------------------------
function s.spfilter(c,tp)
	return c:IsControler(1-tp)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.spfilter,1,nil,tp)
end

--------------------------------
-- ② 타깃: 덱에서 "Over Limit" 몬스터 1장 서치
--------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc48) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.lrgyfilter(c)
	return c:IsCode(23171610)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--------------------------------
-- ② 처리:
--  1) "Over Limit" 몬스터 서치
--  2) 그 후, 묘지에 "Limiter Removal" 이 있고
--	 상대 필드에 몬스터가 있다면,
--	 선택적으로 그 중 1장의 ATK를 1500 감소
--------------------------------
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1) 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
		end
	else
		return
	end

	-- 2) 묘지에 Limiter Removal 존재 + 상대 필드 몬스터 존재 확인
	if not Duel.IsExistingMatchingCard(s.lrgyfilter,tp,LOCATION_GRAVE,0,1,nil) then return end
	if not Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) then return end

	-- 선택적으로 공격력 감소 효과 사용
	if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
		local tc=tg:GetFirst()
		if tc then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-1500)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end
