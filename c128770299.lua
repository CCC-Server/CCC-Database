local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--② 소재/장착/자기효과 파괴 시 발동
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.trcon)
	e2:SetTarget(s.trtg)
	e2:SetOperation(s.trop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
--① 패에서 특소 조건
function s.cfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0x763) or c:IsSetCard(0x764) or c:IsSetCard(0x765))
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-------------------------------------------------
--② 조건: 엑시즈 소재가 되었거나 / 장착되었거나 / 자신 카드 효과로 파괴되어 묘지로 간 경우
function s.trcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 엑시즈 소재가 된 경우 or 장착된 경우는 PreviousLocation 체크
	local became_material = c:IsPreviousLocation(LOCATION_OVERLAY)
	local became_equip = c:IsPreviousLocation(LOCATION_SZONE) and c:IsReason(REASON_LOST_TARGET)
	-- 자신의 카드 효과로 파괴된 경우
	local destroyed_by_self = c:IsReason(REASON_DESTROY) and re and re:GetOwnerPlayer()==tp
	return became_material or became_equip or destroyed_by_self
end

-------------------------------------------------
--② 효과 선택
function s.thfilter(c)
	return (c:IsSetCard(0x763) or c:IsSetCard(0x764) or c:IsSetCard(0x765))
		and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.trtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	if chk==0 then return b1 or b2 end
	local op=0
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		Duel.SelectOption(tp,aux.Stringid(id,2))
		op=0
	else
		Duel.SelectOption(tp,aux.Stringid(id,3))
		op=1
	end
	e:SetLabel(op)
	if op==0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
	else
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end
function s.trop(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end
