--차원교화관 아니스
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Link Summon Procedure
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xda2),2,2)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK) end)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.rmeffcon)
	c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField()  end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_STZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_STZONE,1,1,nil)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetValue(LOCATION_DECKSHF)
		e1:SetReset(RESET_EVENT|RESETS_REDIRECT|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e1,true)
	end
end
function s.rmeffcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return ep==tp and re:IsMonsterEffect() and rc:IsSetCard(0xda2) and rc:IsLocation(LOCATION_MZONE)
end