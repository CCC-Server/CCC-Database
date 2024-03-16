--초전사의 빛
Duel.LoadScript("archetype_seihai.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Ritual.CreateProc({
		handler=c,
		lvtype=RITPROC_EQUAL,
		filter=aux.FilterBoolFunction(Card.IsSetCard,SET_BLACK_LUSTER_SOLDIER),
		desc=aux.Stringid(id,0),
		extrafil=s.extragroup,
		extraop=s.extraop,
		location=LOCATION_HAND|LOCATION_GRAVE,
		forcedselection=s.ritcheck,
		extratg=s.extratg
	})
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end
s.listed_series={SET_GAIA_THE_FIERCE_KNIGHT,SET_BLACK_LUSTER_SOLDIER,ARCHETYPE_SUPER_SOLDIER}
--Activate
function s.extragroup(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_DECK,0,nil)
end
function s.matfilter1(c)
	return (c:IsSetCard(SET_GAIA_THE_FIERCE_KNIGHT) or c:IsArchetype(ARCHETYPE_SUPER_SOLDIER)) and c:IsAbleToGrave() and c:IsLevelAbove(1)
end
function s.extraop(mat,e,tp,eg,ep,ev,re,r,rp,tc)
	local mat2=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)
	mat:Sub(mat2)
	Duel.ReleaseRitualMaterial(mat)
	Duel.SendtoGrave(mat2,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.ritcheck(e,tp,g,sc)
	return g:FilterCount(Card.IsLocation,nil,LOCATION_DECK)<=1
end
