local s,id=GetID()
local CHILSEOK_CODE=128770423 -- "수왕권사-칠석"

function s.initial_effect(c)
	-- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x770),2,2)
	c:EnableReviveLimit()

	-- Overlay Xyz Summon using "수왕권사-칠석"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.ovcon)
	e0:SetOperation(s.ovop)
	c:RegisterEffect(e0)

	-- ① Cannot be targeted by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- ② Declare 1 Race; all monsters become that Race
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.bpcon)
	e2:SetOperation(s.raceop)
	c:RegisterEffect(e2)

	-- ③ Copy effect of a "수왕권사" Xyz monster
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.copytg)
	e3:SetOperation(s.copyop)
	c:RegisterEffect(e3)

	-- ④ End of Battle Phase: Special Summon "수왕권사-칠석" and return this card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.retcon)
	e4:SetOperation(s.retop)
	c:RegisterEffect(e4)
end

-- --------------------
-- Overlay Xyz Summon
-- --------------------
function s.ovcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.ovfilter(c,tp)
	return c:IsFaceup() and c:IsCode(CHILSEOK_CODE)
		and c:IsCanBeXyzMaterial(nil,tp)
end

function s.ovop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local tc=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil,tp):GetFirst()
	if not tc then return end
	local mg=tc:GetOverlayGroup()
	if #mg>0 then
		Duel.SendtoGrave(mg,REASON_RULE)
	end
	c:SetMaterial(Group.FromCards(tc))
	Duel.Overlay(c,Group.FromCards(tc))
end

-- --------------------
-- ② Battle Phase check
-- --------------------
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

-- --------------------
-- ② Change all monsters' Race
-- --------------------
function s.raceop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RACE)
	local rc=Duel.AnnounceRace(tp,1,RACE_ALL)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_RACE)
		e1:SetValue(rc)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

-- --------------------
-- ③ Copy "수왕권사" Xyz effect
-- --------------------
function s.copyfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x770) and c:IsType(TYPE_XYZ)
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.copyfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (c:IsFaceup() and tc and tc:IsFaceup()) then return end
	-- Copy original effects until end of turn
	c:CopyEffect(tc:GetOriginalCode(),RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,1)
end

-- --------------------
-- ④ Return and Special Summon "수왕권사-칠석"
-- --------------------
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()>0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=c:GetOverlayGroup():Filter(Card.IsCode,nil,CHILSEOK_CODE)
	if #g==0 then return end
	local tc=g:GetFirst()
	c:RemoveOverlayCard(tp,tc,tc,REASON_EFFECT)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end
