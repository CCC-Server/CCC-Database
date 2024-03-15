--암흑 초전사 가이아
Duel.LoadScript("archetype_seihai.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Special summon procedure
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,function(re) return not re:IsMonsterEffect() end)
	--Set a card and Special summon a token
	local e2=Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end
s.listed_names={id+1}
s.listed_series={SET_GAIA_THE_FIERCE_KNIGHT,SET_BLACK_LUSTER_SOLDIER,ARCHETYPE_SUPER_SOLDIER}
--Special summon procedure
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetCustomActivityCount(id,1-tp,ACTIVITY_CHAIN)>0
end
--Set a card and Special summon a token
function s.stfilter(c)
	return c:IsRitualSpell() and c:IsArchetype(ARCHETYPE_SUPER_SOLDIER)
		and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,0,0,1,RACE_WARRIOR,ATTRIBUTE_EARTH) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_DECK,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local sg=Duel.SelectMatchingCard(tp,s.stfilter,tp,LOCATION_DECK,0,1,1,nil)
	if Duel.SSet(tp,sg)>0
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,0,0,1,RACE_WARRIOR,ATTRIBUTE_EARTH) then
			local token=Duel.CreateToken(tp,id+1)
			if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)>0 then
				--Cannot activate effect of monsters
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetDescription(aux.Stringid(id,2))
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
				e1:SetCode(EFFECT_CANNOT_ACTIVATE)
				e1:SetRange(LOCATION_MZONE)
				e1:SetTargetRange(1,0)
				e1:SetValue(function(_,re) return not s.actfilter(re) end)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_CONTROL)
				token:RegisterEffect(e1)
			end
	end
end
function s.actfilter(re)
	local rc=re:GetHandler()
	return not (re:IsMonsterEffect() and not rc:IsSetCard(SET_BLACK_LUSTER_SOLDIER) and not rc:IsSummonableCard())
end
