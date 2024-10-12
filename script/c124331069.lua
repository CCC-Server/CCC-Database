--데이브레이크 이클립스
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	local f0=Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xda6),3)[1]
	f0:SetDescription(aux.Stringid(id,0))
	local f1=Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xda6),1,s.ffilter,1)[1]
	f1:SetDescription(aux.Stringid(id,1))
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(id)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	c:RegisterEffect(e1)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.rmvcond)
	e3:SetTarget(s.rmvtg)
	e3:SetOperation(s.rmvop)
	c:RegisterEffect(e3)
end

function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(0xda6,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp)
end
function s.rmvcond(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler():IsSetCard(0xda6) and rp==tp
end
function s.rmvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetMatchingGroupCount(Card.IsAbleToRemove,tp,0,LOCATION_HAND,nil,tp,POS_FACEUP)>0 end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
end
function s.rmfilter(c,cd)
	return c:IsFaceup() and c:IsAbleToRemove() and c:GetOriginalCode()==cd
end
function s.rmvop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g==0 then return end
	Duel.ConfirmCards(tp,g)
	if g:IsExists(Card.IsAbleToRemove,1,nil,tp,POS_FACEDOWN) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local tc=g:FilterSelect(tp,Card.IsAbleToRemove,1,1,nil,tp,POS_FACEUP):GetFirst()
		if tc then
			Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
			Duel.ShuffleHand(1-tp)
			local rg=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,nil,tc:GetOriginalCode())
			if #rg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.BreakEffect()
				Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end
