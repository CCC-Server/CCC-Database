--Fortune Lady [카드명]
local s,id=GetID()
function s.initial_effect(c)
	-- This card's effects ③, ④, and ⑤ can only be used once per turn.
	-- ①: During your Standby Phase: Increase this card's Level by 1.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(function(e,tp) return Duel.GetTurnPlayer()==tp end)
	e1:SetOperation(function(e,tp) 
		local c=e:GetHandler() 
		if c:IsFaceup() and c:IsRelateToEffect(e) then 
			local e1_level_up=Effect.CreateEffect(c) 
			e1_level_up:SetType(EFFECT_TYPE_SINGLE) 
			e1_level_up:SetCode(EFFECT_UPDATE_LEVEL) 
			e1_level_up:SetValue(1) 
			e1_level_up:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE) 
			c:RegisterEffect(e1_level_up) 
		end 
	end)
	c:RegisterEffect(e1)

	-- ②: This card's ATK becomes this card's Level x 400.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_ATTACK) -- Use SET_ATTACK for direct calculation based on level
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(function(e,c) return c:GetLevel()*400 end)
	c:RegisterEffect(e2)

	-- ③: If a "Fortune Lady" monster exists on your field, you can Special Summon this card (from your hand).
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_SPSUMMON_PROC)
	e3:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- Once per turn for effect ③
	e3:SetCondition(function(e,c) 
		if c==nil then return true end 
		return Duel.IsExistingMatchingCard(function(card) return card:IsFaceup() and card:IsSetCard(0x31) end,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil) 
	end)
	c:RegisterEffect(e3)

	-- ④: If this card is Special Summoned: You can banish 1 "Fortune Lady" monster from your field, and if you do, Special Summon 1 "Fortune Lady" monster from your Deck with a Level less than or equal to the banished monster's Level. You can only Special Summon Synchro Monsters from the Extra Deck the turn you activate this effect.
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH) -- Once per turn for effect ④
	e4:SetTarget(s.sptg4)
	e4:SetOperation(s.spop4)
	c:RegisterEffect(e4)

	-- ⑤: If this card is sent to the GY as Synchro Material, or leaves the field by a "Fortune Lady" card's effect: You can Special Summon this card from your GY/banished zone.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCountLimit(1,{id,2},EFFECT_COUNT_CODE_OATH) -- Once per turn for effect ⑤
	e5:SetCondition(s.spcon5)
	e5:SetTarget(s.sptg5)
	e5:SetOperation(s.spop5)
	
	-- Register the effect for both going to GY and being banished
	e5:SetCode(EVENT_TO_GRAVE) -- If sent to GY
	c:RegisterEffect(e5)

	local e5_b=e5:Clone() -- Clone the effect for being banished
	e5_b:SetCode(EVENT_REMOVE) -- If banished
	e5_b:SetCondition(s.spcon5_removed) -- A slightly different condition for being removed (banished)
	c:RegisterEffect(e5_b)
end

-- ④ related functions
function s.sptg4(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0x31) and c:IsAbleToRemove() and c:GetLevel()>0 end,tp,LOCATION_MZONE,0,1,nil) 
			and Duel.IsExistingMatchingCard(function(tc) return tc:IsSetCard(0x31) and tc:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,LOCATION_DECK,0,1,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop4(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=Duel.SelectMatchingCard(tp,function(c) return c:IsFaceup() and c:IsSetCard(0x31) and c:IsAbleToRemove() and c:GetLevel()>0 end,tp,LOCATION_MZONE,0,1,1,nil)
	local rc=rg:GetFirst()
	if rc and Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)>0 then
		local lv=rc:GetLevel()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x31) and c:GetLevel()<=lv and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then 
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP) 
			-- Synchro Monster Special Summon restriction from Extra Deck
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetTargetRange(1,0)
			e1:SetTarget(function(_,c) 
				-- If the monster is being Special Summoned from the Extra Deck,
				-- it must be a Synchro Monster.
				if c:IsLocation(LOCATION_EXTRA) then 
					return not c:IsType(TYPE_SYNCHRO) 
				end
				-- Other Special Summons (from hand, deck, GY, banished) are not restricted.
				return false 
			end)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end

-- ⑤ related functions
-- Condition for when it's sent to the GY
function s.spcon5(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Sent to GY as Synchro Material
	if bit.band(r, REASON_MATERIAL+REASON_SYNCHRO) == (REASON_MATERIAL+REASON_SYNCHRO) then
		return true
	end
	-- Sent to GY by a "Fortune Lady" card's effect
	if bit.band(r, REASON_EFFECT) ~= 0 and re and re:GetHandler():IsSetCard(0x31) then
		return true
	end
	return false
end

-- Condition for when it's banished
function s.spcon5_removed(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Banished by a "Fortune Lady" card's effect
	-- Note: Synchro Material usually goes to GY, not banished.
	-- So we only check for REASON_EFFECT and Fortune Lady card.
	return bit.band(r, REASON_EFFECT) ~= 0 and re and re:GetHandler():IsSetCard(0x31)
end

function s.sptg5(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop5(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- No need for c:IsRelateToEffect(e) here for Special Summon from GY/Banished
	-- as it's already in the correct location for the summon.
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end