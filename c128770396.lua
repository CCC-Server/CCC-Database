local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 7 "Archeoseeker" monsters
	c:EnableReviveLimit()
	Fusion.AddProcFunRep(c,aux.FilterBoolFunction(Card.IsSetCard,0x769),7,true)

	-- Custom Special Summon Procedure
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	-- On Special Summon: Choose and apply effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.effect_choice)
	c:RegisterEffect(e1)

	-- Global Race Tracker
	if not s.global_check then
		s.global_check=true
		s.type_summons = {}
		local ge1=Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SUMMON_SUCCESS)
		ge1:SetOperation(s.track_race)
		Duel.RegisterEffect(ge1,0)
		local ge2=ge1:Clone()
		ge2:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(ge2,0)
		local ge3=Effect.GlobalEffect()
		ge3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge3:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge3:SetOperation(function()
			s.type_summons[Duel.GetTurnPlayer()] = {}
		end)
		Duel.RegisterEffect(ge3,0)
	end
end

-- 🧠 Track different Types (Races) summoned
function s.track_race(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		local p = tc:GetSummonPlayer()
		if not s.type_summons[p] then s.type_summons[p] = {} end
		s.type_summons[p][tc:GetRace()] = true
	end
end

-- 📌 Special Summon Condition
function s.spcon(e,c)
	if c==nil then return true end
	local tp = c:GetControler()
	local count = s.get_type_count(tp)
	if count >= 7 then return true end
	if count < 5 then return false end
	if Duel.GetLocationCount(tp,LOCATION_MZONE) <= -3 then return false end
	local g = Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_MZONE,0,nil)
	return s.has_diff_race(g,3)
end

-- 📌 Special Summon Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	if s.get_type_count(tp) >= 7 then return end
	local g = Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local sg = g:Select(tp,3,3,nil)
	if not s.has_diff_race(sg,3) then return end
	Duel.Release(sg,REASON_COST)
end

-- ✅ Check N different Races in Group
function s.has_diff_race(g,n)
	local check = {}
	for tc in aux.Next(g) do check[tc:GetRace()] = true end
	local ct = 0
	for _,v in pairs(check) do if v then ct = ct + 1 end end
	return ct >= n
end

-- ✅ Count different Races Summoned this turn
function s.get_type_count(tp)
	local t = s.type_summons[tp] or {}
	local count = 0
	for _,v in pairs(t) do if v then count = count + 1 end end
	return count
end

-- 🧠 Effect choice and duplication
function s.effect_choice(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	local max = s.get_type_count(tp)
	if max == 0 then return end

	local effects = {
		{name="Can attack twice", apply=function(tc)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EXTRA_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
		end},

		{name="ATK/DEF +1000", apply=function(tc)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(1000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			tc:RegisterEffect(e2,true)
		end},

		{name="Unaffected by targeting effects", apply=function(tc)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
			e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
			e1:SetRange(LOCATION_MZONE)
			e1:SetValue(aux.tgoval)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
		end},

		{name="Cannot be destroyed by battle", apply=function(tc)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
		end},

		{name="Destroy monster after battle", apply=function(tc)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DESTROY_BATTLE)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
		end},

		{name="Opponent must attack this card", apply=function(tc)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_MUST_ATTACK)
			e1:SetTargetRange(0,LOCATION_MZONE)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)

			local e2=Effect.CreateEffect(tc)
			e2:SetType(EFFECT_TYPE_FIELD)
			e2:SetCode(EFFECT_MUST_ATTACK_MONSTER)
			e2:SetTargetRange(0,LOCATION_MZONE)
			e2:SetValue(function(e,c) return c==tc end)
			e2:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e2,tp)
		end}
	}

	local selected = {}
	for i=1,math.min(#effects, max) do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
		local choices = {}
		local index_map = {}
		for j,effect in ipairs(effects) do
			if not selected[j] then
				table.insert(choices, effect.name)
				table.insert(index_map, j)
			end
		end

		-- 선택된 옵션 인덱스 (1-based)
		local opt = Duel.SelectOption(tp,table.unpack(choices)) + 1
		local chosen = index_map[opt]
		if chosen then
			effects[chosen].apply(c)
			selected[chosen] = true
			s.register_effect_copy(c, effects[chosen].apply)
		end
	end
end

-- 📌 Save effect to be shared with future monsters
function s.register_effect_copy(card, apply_func)
	if not s.shared_effects then s.shared_effects = {} end
	table.insert(s.shared_effects, apply_func)

	-- Listener to apply these effects to monsters summoned later
	if not s.effect_copy_listener then
		s.effect_copy_listener = true
		local ge=Effect.GlobalEffect()
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_SUMMON_SUCCESS)
		ge:SetOperation(s.copy_to_summoned)
		Duel.RegisterEffect(ge,0)
		local ge2=ge:Clone()
		ge2:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(ge2,0)
	end
end

-- ⏩ Copy saved effects to newly summoned monsters
function s.copy_to_summoned(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		if tc:IsControler(tp) and tc:IsLocation(LOCATION_MZONE) and s.shared_effects then
			for _,apply in ipairs(s.shared_effects) do
				apply(tc)
			end
		end
	end
end

