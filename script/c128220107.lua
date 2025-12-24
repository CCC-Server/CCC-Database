--F로그라이크 더 퍼니시먼트 듀
local s,id=GetID()
function c128220107.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
local g=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if chk==0 then 
		return g:IsExists(Card.IsMonster,1,nil) 
			or g:IsExists(Card.IsSpell,1,nil) 
			or g:IsExists(Card.IsTrap,1,nil) 
	end
	local show_g=Group.CreateGroup()
	local types={TYPE_MONSTER,TYPE_SPELL,TYPE_TRAP}
	for _,v in ipairs(types) do
		if g:IsExists(Card.IsType,1,nil,v) then
			if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then 
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
				local sg=g:FilterSelect(tp,Card.IsType,1,1,nil,v)
				show_g:Merge(sg)
			end
		end
	end
	if #show_g>0 then
		Duel.ConfirmCards(1-tp,show_g)
		e:SetLabel(#show_g)
	else
		return false
	end
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local count=e:GetLabel() 
	if count>=2 then
		local dg=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,dg,1,0,0)
	end
	if count>=3 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
local count=e:GetLabel()
	if count<1 then return end
	if count>=1 then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil):Filter(Card.IsRace,nil,RACE_ZOMBIE)
		local tc=g:GetFirst()
		while tc do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(1400)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			tc=g:GetNext()
		end
	end
	if count>=2 then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local dg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #dg>0 then
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
	if count>=3 then
		Duel.BreakEffect()
		local params = {
			fusfilter = function(c) return c:IsRace(RACE_ZOMBIE) end,
			matfilter = function(c) return c:IsLocation(LOCATION_GRAVE+LOCATION_MZONE) end,
			extraop = Fusion.BanishMaterial,
			extratg = function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then return true end
				Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE+LOCATION_MZONE)
			end
		}
		local f_eff = Fusion.SummonEffOP(params)
		f_eff(e,tp,eg,ep,ev,re,r,rp)
	end
end
function s.cfilter(c,tp)
	return c:IsControler(tp) and not c:IsReason(REASON_DRAW)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end