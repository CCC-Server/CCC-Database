--Crimson Dragon / Assault Mode
local s,id=GetID()
local CARD_CRIMSON_DRAGON=63436931
local CARD_ASSAULT_MODE=80280737 -- ✅ "버스터 모드"로 수정
local CARD_ASSAULT_MODE_ACTIVATE=80259861
local SET_ASSAULT_MODE=0x2012

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Must be Special Summoned with "Assault Mode Activate"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(function(e,se,sp,st)
		return se and se:GetHandler():IsCode(CARD_ASSAULT_MODE_ACTIVATE)
	end)
	c:RegisterEffect(e0)

	-- (1) On Special Summon: Search
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- (2) Quick Effect: Synchro Replace
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sctg)
	e2:SetOperation(s.scop)
	c:RegisterEffect(e2)

	-- (3) If destroyed: Revive Crimson Dragon
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(function(e) return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD) end)
	e3:SetTarget(s.revtg)
	e3:SetOperation(s.revop)
	c:RegisterEffect(e3)
end

-- Required for "Assault Mode Activate" to find this card
s.listed_names={CARD_CRIMSON_DRAGON,CARD_ASSAULT_MODE,CARD_ASSAULT_MODE_ACTIVATE}
s.assault_mode=CARD_CRIMSON_DRAGON

---------------------------------------------------------------
-- (1) Search - fixed to correctly find "Buster Mode" or "Crimson Dragon" S/T
---------------------------------------------------------------
function s.thfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
		and (c:ListsCode(CARD_CRIMSON_DRAGON) or c:ListsCode(CARD_ASSAULT_MODE))
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

---------------------------------------------------------------
-- (2) Quick Synchro Replacement (unchanged)
---------------------------------------------------------------
function s.scfilter(c,e,tp)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsLevelAbove(7)
		and Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c:GetLevel())
end
function s.synfilter(c,e,tp,lv)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_SYNCHRO) and c:IsLevel(lv)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(tp) and s.scfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.scfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.scfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local lv=tc:GetLevel()
	local g=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,lv)
	local sc=g:GetFirst()
	if sc and Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,true,false,POS_FACEUP)~=0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		sc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		sc:RegisterEffect(e2)
	end
end

---------------------------------------------------------------
-- (3) Revive Crimson Dragon
---------------------------------------------------------------
function s.revfilter(c,e,tp)
	return c:IsCode(CARD_CRIMSON_DRAGON) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,true,false)
end
function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.revfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.revfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	local g=Duel.SelectTarget(tp,s.revfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,tp,0)
end
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,true,false,POS_FACEUP)
	end
end
