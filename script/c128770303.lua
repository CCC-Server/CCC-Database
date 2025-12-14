local s,id=GetID()
function s.initial_effect(c)
	--① 덱으로 되돌리고 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.setcost)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--② 배틀 페이즈 중 상대 마/함 발동 제한
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.actcon)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)
end

--① 코스트: 자신을 덱으로 되돌림
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeckAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
--① 세트 대상
function s.setfilter(c)
	return c:IsSetCard(0x763) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		Duel.ConfirmCards(1-tp,g)
	end
end

--② 상대 마/함 발동 제한
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not a or not d then return false end
	-- 자신 필드의 "네메시스 퍼펫" 몬스터가 전투를 실행 중인 경우
	return Duel.GetCurrentPhase()==PHASE_BATTLE and 
		((a:IsControler(tp) and a:IsSetCard(0x763)) or (d and d:IsControler(tp) and d:IsSetCard(0x763)))
end
function s.aclimit(e,re,tp)
	-- 상대가 마법 또는 함정 카드를 발동하려는 경우 제한
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end
