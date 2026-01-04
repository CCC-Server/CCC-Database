--스타브 네오 클리어윙 퓨전 드래곤
--Starve Neo Clear Wing Fusion Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon
	c:EnableReviveLimit()
	--Materials: DARK Fusion Monster + Monster Special Summoned from the Extra Deck (Fusion/Synchro/Xyz/Link)
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)

	--Treat as "Predaplant" in name/rules
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x10f3) -- Predaplant
	c:RegisterEffect(e0)

	--[Effect 1] Negate monster effect, banish it, gain ATK
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--[Effect 2] If opponent Special Summons from Extra Deck: put Predator Counters, then SS a Fusion <=8 from Extra (Starving Venom/Predaplant)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COUNTER+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.counter_list={COUNTER_PREDATOR}
s.listed_series={0x1050,0x10f3} -- Starving Venom, Predaplant

--Fusion material filters
function s.matfilter1(c,fc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp)
end
function s.matfilter2(c,fc,sumtype,tp)
	--Must have been Special Summoned from the Extra Deck
	return c:IsSummonLocation(LOCATION_EXTRA)
		and c:IsType(TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK,fc,sumtype,tp)
end

--Effect 1 (Negate/Remove/ATK)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsStatus(STATUS_BATTLE_DESTROYED) or not Duel.IsChainNegatable(ev) then return false end
	return rp~=tp and re:IsActiveType(TYPE_MONSTER)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if rc and rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and rc and rc:IsRelateToEffect(re) then
		--Banish the monster that activated
		if Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)>0 then
			local atk=rc:GetBaseAttack()
			if atk>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(atk)
				e1:SetReset(RESETS_STANDARD_PHASE_END)
				c:RegisterEffect(e1)
			end
		end
	end
end

--Effect 2 trigger: opponent Special Summoned from Extra Deck (Fusion/Synchro/Xyz/Link)
function s.spfilter(c,tp)
	return c:IsSummonPlayer(1-tp)
		and c:IsSummonLocation(LOCATION_EXTRA)
		and c:IsType(TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.spfilter,1,nil,tp)
end

--Fusion to Summon from Extra: Predaplant or Starving Venom, Fusion, Level <= 8
function s.sumfilter(c,e,tp)
	if not (c:IsSetCard(0x1050) or c:IsSetCard(0x10f3)) then return false end
	if not (c:IsType(TYPE_FUSION) and c:HasLevel() and c:GetLevel()<=8) then return false end
	return c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,true)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,1,0,COUNTER_PREDATOR)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(s.spfilter,nil,tp)

	--Put Predator Counters + Level becomes 1 (only for monsters that have Levels)
	for tc in aux.Next(g) do
		tc:AddCounter(COUNTER_PREDATOR,1)
		if tc:GetCounter(COUNTER_PREDATOR)>0 and tc:HasLevel() and tc:GetLevel()>1 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetCondition(s.lvcon)
			tc:RegisterEffect(e1)
		end
	end

	--Special Summon from Extra as Fusion Summon
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=sg:GetFirst()
	if sc then
		Duel.BreakEffect()
		if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,true,POS_FACEUP)>0 then
			sc:CompleteProcedure()
		end
	end
end

function s.lvcon(e)
	return e:GetHandler():GetCounter(COUNTER_PREDATOR)>0
end
