local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------------------------------
	-- Effect 1: Special Summon from hand if you control/GY an Xyz
	---------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	---------------------------------------------------------------
	-- Effect 2: Declare → Reveal → Damage → Xyz Evolution
	---------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE + CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(seondtg)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

------------------------------------------------------------
-- E1
------------------------------------------------------------
function s.spfilter(c)
	return c:IsType(TYPE_XYZ)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)
end

------------------------------------------------------------
-- E2 준비
------------------------------------------------------------
local type_map={
	[0]=TYPE_MONSTER,
	[1]=TYPE_SPELL,
	[2]=TYPE_TRAP
}

function s.xyzfilter(c,e,tp,mc)
	return c:IsSetCard(0xc47) and c:IsType(TYPE_XYZ) and c:IsRank(4)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function seondtg(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end

------------------------------------------------------------
-- E2 본체 (셔플 완전 제거)
------------------------------------------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

	----------------------------
	-- Step 1: Declare Type
	----------------------------
	Duel.Hint(HINT_SELECTMSG,tp,569)
	local ann=Duel.AnnounceType(tp)
	local real_type = type_map[ann]

	----------------------------
	-- Step 2: Reveal opponent's top card
	----------------------------
	Duel.ConfirmDecktop(1-tp,1)
	local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
	if not tc then return end

	local match = tc:IsType(real_type)

	----------------------------
	-- Step 3: Damage
	----------------------------
	Duel.Damage(1-tp,1000,REASON_EFFECT)

	----------------------------
	-- Step 4: If match → Xyz Evolution
	----------------------------
	if not match then return end
	if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end

	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
	if #pg>1 or (#pg==1 and not pg:IsContains(c)) then return end

	if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then return end

	----------------------------
	-- Step 5: Select Xyz
	----------------------------
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
	if not xyz then return end

	Duel.BreakEffect()

	----------------------------
	-- Step 6: Xyz Evolution
	----------------------------
	if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		local mg=Group.FromCards(c)
		xyz:SetMaterial(mg)
		Duel.Overlay(xyz,mg)
		xyz:CompleteProcedure()
	end
end
