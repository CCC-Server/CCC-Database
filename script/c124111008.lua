--〈영원한 후일담〉
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.spfilter(c,e,tp)
	return c:IsLevelAbove(1) and c:IsRace(RACE_ZOMBIE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) and g:IsExists(Card.IsType,1,nil,TYPE_NORMAL) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.filter(sg)
	return sg:IsExists(Card.IsType,1,nil,TYPE_NORMAL)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(function(_,c) return c:IsLocation(LOCATION_EXTRA) or not c:IsRace(RACE_ZOMBIE) end)
		e1:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e1,tp)
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
	if not g:IsExists(Card.IsType,1,nil,TYPE_NORMAL) then return end
	local ft=math.min(Duel.GetLocationCount(tp,LOCATION_MZONE),#g,ct)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,ft,s.filter,1,tp,HINTMSG_SPSUMMON,s.filter)
	Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
end
