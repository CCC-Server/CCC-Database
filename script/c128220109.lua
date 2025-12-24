--F로그라이크 토네이도 오브 소울즈
local s,id=GetID()
function c128220109.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
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
		local tg=g:Filter(Card.IsType,nil,v)
		if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then -- "카드를 보여주겠습니까?"
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
			local sg=tg:Select(tp,1,1,nil)
			show_g:Merge(sg)
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
	if count>=3 then
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	end
end
function s.actfilter(c,e,tp,eg,ep,ev,re,r,rp)
	return c:IsSetCard(0xc25) and (c:IsSpell() or c:IsTrap()) and not c:IsCode(id)
		and c:CheckActivateEffect(false,true,false)~=nil
end
function s.thfilter(c)
	return c:IsSetCard(0xc25) and c:IsSpellTrap()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local count=e:GetLabel()
	if count<1 then return end
	if count>=1 then
		local dg=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		for tc in aux.Next(dg) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-700)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
	if count>=2 then
		local sg=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g==0 then return end
		Duel.BreakEffect()
		Duel.SendtoHand(g,tp,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		end
	if count>=3 then
		Duel.BreakEffect()
		local killg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
		if #killg>0 then
			Duel.Destroy(killg,REASON_EFFECT)
		end
	end
end