-- World Guardian Continuous Spell
-- Scripted by Gemini
local s,id=GetID()
function s.initial_effect(c)
	-- (1) Activate: When activated, you can Set 1 "World Guardian" Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	-- Note: Removed SetCategory(CATEGORY_TOFIELD) as it caused an error. 
	-- Setting from Deck/GY doesn't strictly require a category unless it adds to hand (CATEGORY_SEARCH).
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- (2) Destroy: If opponent activates effect while you control "World Guardian"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id+1) -- Standard way to set HOPT for specific effect
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- "World Guardian" archetype code
s.listed_series={0xc52}

function s.filter(c)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL) and c:IsSSetable() and not c:IsCode(id)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- Continuous Spell can always activate to be placed on field
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	-- Ask player if they want to use the effect to Set
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		e:SetLabel(1)
		-- Removed SetOperationInfo for CATEGORY_TOFIELD
	else
		e:SetLabel(0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()~=1 then return end -- Player chose not to use the effect
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end

function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp -- Opponent activated
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) -- You control World Guardian monster
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end