--판타즈마 아틀리에
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(aux.bfgcost)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.dptg)
	e2:SetOperation(s.dpop)
	c:RegisterEffect(e2)
end
function s.spfilter2(c,fg,minmat,maxmat)
	return c:IsLinkSummonable(nil,fg,minmat,maxmat)
end
function s.rescon(sg,e,tp,mg)
	return Duel.GetMatchingGroupCount(s.spfilter2,tp,LOCATION_EXTRA,0,nil,sg,#sg,#sg)>0
end
function s.filtercheck(c,e,tp)
	return c:IsCanBeLinkMaterial() and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and c:IsSetCard(0xda5)
		and c:IsFaceup() and c:IsLocation(LOCATION_SZONE)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local fg=Duel.GetMatchingGroup(s.filtercheck,tp,LOCATION_SZONE,0,nil,e,tp)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	if chk==0 then return ft>0 and Duel.IsPlayerCanSpecialSummonCount(tp,2)
		and Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_LINK)>0
		and aux.SelectUnselectGroup(fg,e,tp,1,ft,s.rescon,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_SZONE+LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local fg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.filtercheck),tp,LOCATION_SZONE,0,nil,e,tp)
	if ft<1 or not Duel.IsPlayerCanSpecialSummonCount(tp,2) then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	local g=aux.SelectUnselectGroup(fg,e,tp,1,ft,s.rescon,1,tp,HINTMSG_SPSUMMON,s.rescon,nil,false)
	if not g or #g==0 then return end
	local c=e:GetHandler()
	for tc in aux.Next(g) do
		Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP)
	end
	Duel.SpecialSummonComplete()
	local tg=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_EXTRA,0,nil,g,#g,#g)
	if #tg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=tg:Select(tp,1,1,nil)
		local sc=sg:GetFirst()
		Duel.LinkSummon(tp,sc,nil,g,#g,#g)
	end
end
function s.dpfilter(c)
	return c:IsSetCard(0xda5) and c:IsMonster()
end

function s.dptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dpfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_HAND,0,1,nil) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.dpop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.dpfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_HAND,0,1,1,nil):GetFirst()
	if g then
		Duel.MoveToField(g,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD&~RESET_TURN_SET)
		g:RegisterEffect(e1)
	end
end
