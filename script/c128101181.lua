--Cyber Supporter (임시 카드명)
local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Reveal and Special Summon "Cyber Dragon" from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effect 2: Fusion Summon from GY (in response to opponent's monster effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.fuscon)
	e2:SetCost(s.fuscost)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

-- Effect 1: Cost (Reveal this card)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.ConfirmCards(1-tp,e:GetHandler())
end

-- Effect 1: Filter for "Cyber Dragon" monster
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x1093) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Effect 1: Target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- Effect 1: Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local tg=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,nil)
		if #tg>0 then
			Duel.SendtoGrave(tg,REASON_DISCARD+REASON_COST)
		end
	end
end

-- Effect 2: Condition (only when opponent activates a monster effect)
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActivated() and re:IsActiveType(TYPE_MONSTER) and rp~=tp
end

-- Effect 2: Cost (banish this card from GY)
function s.fuscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- Effect 2: Target (must be able to Fusion Summon a Machine Fusion monster)
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(function(c) return c:IsType(TYPE_MONSTER) end,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(function(c) return c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION) end,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- Effect 2: Operation (Fusion Summon using hand/field materials)
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetFusionMaterial(tp)
	local sg=Duel.GetMatchingGroup(function(c) return c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION) end,tp,LOCATION_EXTRA,0,nil)
	if #sg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=sg:Select(tp,1,1,nil):GetFirst()
	if tc then
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,tp)
		if #mat>0 then
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end
