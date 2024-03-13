--초전사의 빛
Duel.LoadScript("archetype_seihai.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	Ritual.AddProc({
		handler=c,
		lvtype=RITPROC_EQUAL,
		filter=aux.FilterBoolFunction(Card.IsSetCard,SET_BLACK_LUSTER_SOLDIER),
		extrafil=s.extragroup,
		extraop=s.extraop,
		location=LOCATION_HAND|LOCATION_GRAVE,
		forcedselection=s.ritcheck,
		extratg=s.extratg
	})
	--Search
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCost(aux.bfgcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end
s.listed_names={CARD_BLACK_LUSTER_SOLDIER}
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
--Search
function s.thfilter1(c)
	return c:IsArchetype(ARCHETYPE_SUPER_SOLDIER) and c:IsRitualSpell() and c:IsAbleToHand()
end
function s.thfilter2(c)
	return c:IsSetCard(SET_BLACK_LUSTER_SOLDIER) and c:IsRitualMonster() and c:IsAbleToHand()
end
function s.thfilter(c)
	return s.thfilter1(c) or s.thfilter2(c)
end
function s.rescon(sg,e,tp,mg)
	return sg:FilterCount(s.thfilter1,nil)==1
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if chk==0 then return #g>=2 and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g<2 then return end
	local thg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_ATOHAND)
	if #thg==2 then
		Duel.SendtoHand(thg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,thg)
		local hg=thg:Filter(Card.IsLocation,nil,LOCATION_HAND)
		if #hg>0 then Duel.ShuffleDeck(tp) end
		if hg:FilterCount(Card.IsCode,nil,CARD_BLACK_LUSTER_SOLDIER)>0
			and Duel.IsPlayerCanDraw(tp,1) then
				Duel.BreakEffect()
				Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end
