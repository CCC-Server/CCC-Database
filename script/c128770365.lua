local s,id=GetID()
function s.initial_effect(c)
   --fusion material
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_FRIGHTFUR),3)

	--①: Unaffected by other card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	--②: Shuffle "Fluffal" cards from GY to release opponent's cards
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_RELEASE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.rltg)
	e2:SetOperation(s.rlop)
	c:RegisterEffect(e2)

	--③: After battle damage → Return to ED and summon other Frightfur
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DAMAGE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_FRIGHTFUR}
s.material_setcode=SET_FRIGHTFUR

--① Immune to other card effects
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--② Shuffle "퍼니멀" cards from GY → Release opponent's cards
function s.rltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsReleasable,tp,0,LOCATION_ONFIELD,1,nil)
	end
end
function s.tdfilter(c)
	return c:IsSetCard(0xa9) and c:IsAbleToDeck()
end
function s.rlop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local tg=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,99,nil)
	if #tg==0 then return end
	local ct=Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.BreakEffect()
	local g=Duel.SelectMatchingCard(tp,Card.IsReleasable,tp,0,LOCATION_ONFIELD,0,ct,ct,nil)
	if #g>0 then
		Duel.Release(g,REASON_EFFECT)
	end
end

--③ Battle damage → Return to ED and summon another Frightfur
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xad) and c:IsType(TYPE_FUSION) and not c:IsCode(128770365) -- Not Chaos Chimera
		and c:IsLevelAbove(8) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
