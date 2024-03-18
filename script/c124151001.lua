--임뷰먼트 오브 블랙
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--레벨 7 몬스터 1장
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsLevel,7),1,1)
	--마법 / 함정에 체인할 수 없다
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(function() return Duel.HasFlagEffect(0,id) end)
	e1:SetOperation(s.chop)
	c:RegisterEffect(e1)
	--패에 넣는다
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--이 턴 몬스터가 앞면 표시로 제외되어 있을 경우
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_REMOVE)
		ge1:SetCondition(s.chcon)
		ge1:SetOperation(function() Duel.RegisterFlagEffect(0,id,RESET_PHASE|PHASE_END,0,1) end)
		Duel.RegisterEffect(ge1,0)
	end)
end
function s.chfilter(c)
	return c:IsFaceup() and c:IsMonster()
end
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.chfilter,1,nil)
end
function s.chop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsSpellTrapEffect() and re:GetOwnerPlayer()==tp then
		Duel.SetChainLimit(s.chlm)
	end
end
function s.chlm(e,ep,tp)
	return ep==tp
end
function s.thfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsLevel(7) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	if g:GetFirst():IsLocation(LOCATION_GRAVE) then
		Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,tp,0)
	end
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc, nil,REASON_EFFECT)
	end
end
