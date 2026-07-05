--섀터드 섀도우 블랙 벌처
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xfa2),s.pfil1)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.con1)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	local e3=e1:Clone()
	e3:SetCode(EVENT_TO_HAND)
	e3:SetCondition(s.con3)
	c:RegisterEffect(e3)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.con2)
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end
function s.pfil1(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp) or (c:IsOnField() and c:IsType(TYPE_EFFECT))
end
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not eg:IsContains(c)
end
function s.nfil3(c)
	return c:IsType(TYPE_MONSTER) and not c:IsReason(REASON_DRAW)
end
function s.con3(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.nfil3,1,nil)
end
function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then
		return #g>0
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()
	if tc and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
	end
end
-- ②번 효과 발동 조건 (블랙 이글과 동일한 오류 방지/호환 보강 버전)
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- rp==1-tp : 상대에 의해 필드에서 벗어났을 경우
	-- c:IsPreviousControler(tp) : 자신 필드에서 존재하고 있었을 경우
	-- c:IsPreviousPosition(POS_FACEUP) : 앞면 표시 상태로 필드를 벗어남
	-- Duel.GetCurrentPhase()~=PHASE_DAMAGE : 데미지 스텝 제외 (안전 수식)
	return rp==1-tp and c:IsPreviousControler(tp) and c:IsPreviousPosition(POS_FACEUP) and Duel.GetCurrentPhase()~=PHASE_DAMAGE
end
function s.tfil2(c)
	return (c:IsCode(24094653) or c:IsCode(48130397)) and c:CheckActivateEffect(true,true,false)~=nil
end
function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local tg=e:GetLabelObject():GetTarget()
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tfil2,tp,LOCATION_GRAVE,0,1,nil)
	end
	e:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e:SetCategory(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.tfil2,tp,LOCATION_GRAVE,0,1,1,nil)
	local te=g:GetFirst():CheckActivateEffect(true,true,false)
	Duel.ClearTargetCard()
	e:SetProperty(te:GetProperty())
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local tg=te:GetTarget()
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end
	te:SetLabel(e:GetLabel())
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	Duel.ClearOperationInfo(0)
	e:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
end
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if te:GetHandler():IsRelateToEffect(e) then
		e:SetLabel(te:GetLabel())
		e:SetLabelObject(te:GetLabelObject())
		local op=te:GetOperation()
		if op then
			op(e,tp,eg,ep,ev,re,r,rp)
		end
		te:SetLabel(e:GetLabel())
		te:SetLabelObject(e:GetLabelObject())
	end
end