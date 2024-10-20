-- 종말의 부름
local s,id=GetID()
function s.initial_effect(c)
	-- Add to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
    	--Register that a player has activated "Millennium Ankh" during this Duel
		aux.GlobalCheck(s,function()
			local ge1=Effect.CreateEffect(c)
			ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			ge1:SetCode(EVENT_CHAIN_SOLVED)
			ge1:SetOperation(s.regop)
			Duel.RegisterEffect(ge1,0)
		end)
	end
	s.listed_names={95308449} --"종언의 카운트 다운"
	function s.regop(e,tp,eg,ep,ev,re,r,rp)
		if not Duel.HasFlagEffect(rp,id) and re:GetHandler():IsCode(95308449) and re:IsHasType(EFFECT_TYPE_ACTIVATE) then
			Duel.RegisterFlagEffect(rp,id,0,0,0)
		end
	end
function s.thfilter(c)
	return c:IsSetCard(0x821) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_NORMAL) and c:IsAttribute(ATTRIBUTE_WATER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g<1 or Duel.SendtoHand(g,nil,REASON_EFFECT)<1 or not g:GetFirst():IsLocation(LOCATION_HAND) then return end
	Duel.ConfirmCards(1-tp,g)
	if Duel.HasFlagEffect(tp,id) then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
		local g=Duel.SelectMatchingCard(tp,Card.IsHasEffect,tp,0x3f,0x3f,1,1,nil,1082946)
		local tc=g:GetFirst()
		local eff={tc:GetCardEffect(1082946)}
		local sel={}
		local seld={}
		local turne
		for _,te in ipairs(eff) do
			table.insert(sel,te)
			table.insert(seld,te:GetDescription())
		end
		if #sel==1 then turne=sel[1] elseif #sel>1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
			local op=Duel.SelectOption(tp,table.unpack(seld))+1
			turne=sel[op]
		end
		if not turne then return end
		local op=turne:GetOperation()
		op(turne,turne:GetOwnerPlayer(),nil,0,id,nil,0,0)
	end
end	
