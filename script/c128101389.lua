--Mist Valley Vice-Commander Executor
local s,id=GetID()
function s.initial_effect(c)
	--(1) Special Summon from hand + add 1 "Mist Valley" from GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	-- 패에서 프리체인 속공 효과로 발동
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)	--"this card's name" OPT (1)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--(2) Bounce your cards, then bounce that many S/T on the field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})	--"this card's name" OPT (2)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	--global check: if any card on the field was returned to the hand this turn
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TO_HAND)
		ge1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
		ge1:SetOperation(s.regop)
		Duel.RegisterEffect(ge1,0)
	end
end

--------------------------------
-- global flag for (1)
--------------------------------
function s.regfilter(c)
	-- was on the field before going to hand
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(s.regfilter,1,nil) then
		-- flag for both players: "a card on the field was returned to the hand this turn"
		for p=0,1 do
			Duel.RegisterFlagEffect(p,id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

--------------------------------
-- (1) Special Summon from hand + add 1 "Mist Valley" from GY
--------------------------------
function s.mvfilter(c)
	-- "Mist Valley" card in GY that can be added to hand
	return c:IsSetCard(SET_MIST_VALLEY) and c:IsAbleToHand()
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- only if at least 1 card on the field was returned to hand this turn
	return Duel.GetFlagEffect(tp,id)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetFlagEffect(tp,id)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.mvfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	-- you cannot Special Summon monsters, except WIND monsters
	return not c:IsAttribute(ATTRIBUTE_WIND)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	-- Special Summon this card from hand
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	-- add 1 "Mist Valley" card from GY to hand
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.mvfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	-- Special Summon restriction for the rest of the turn (non-WIND)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--------------------------------
-- (2) Bounce your cards, then that many S/T on the field
--------------------------------
function s.stfilter(c)
	return c:IsSpellTrap() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- need at least 1 of your cards + at least 1 S/T on the field
		return Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,0,LOCATION_ONFIELD)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- first: return any number of cards you control
	local g1=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,nil)
	if #g1==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	-- "any number" (at least 1)
	local sg1=g1:Select(tp,1,#g1,nil)
	local ct=Duel.SendtoHand(sg1,nil,REASON_EFFECT)
	if ct==0 then return end
	-- then: return that many Spell/Trap Cards on the field to the hand
	local g2=Duel.GetMatchingGroup(s.stfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if #g2==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local sendct=math.min(ct,#g2)
	local sg2=g2:Select(tp,sendct,sendct,nil)
	if #sg2>0 then
		Duel.SendtoHand(sg2,nil,REASON_EFFECT)
	end
end
