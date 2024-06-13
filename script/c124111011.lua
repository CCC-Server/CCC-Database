--〈영원한 후일담〉 오디션
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.cfilter(c,e,tp)
	local lv=c:GetLevel()
	return lv>0 and c:IsRace(RACE_ZOMBIE) and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp,lv)
end
function s.spfilter(c,e,tp,lv)
	return c:IsLevelBelow(lv) and c:IsRace(RACE_ZOMBIE) and c:IsType(TYPE_NORMAL) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil,e,tp) end
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_HAND,0,nil,e,tp)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_DISCARD)
	Duel.SendtoGrave(sg,REASON_COST+REASON_DISCARD)
	e:SetLabel(sg:GetFirst():GetLevel())
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.rescon(sg,e,tp,mg)
	return sg:GetSum(Card.GetLevel)<=e:GetLabel()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local lv=e:GetLabel()
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp,lv)
	if #g==0 then return end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,3,s.rescon,1,tp,HINTMSG_ATOHAND)
	Duel.SendtoHand(sg,nil,REASON_EFFECT)
	Duel.ConfirmCards(1-tp,sg)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(1,0)
	e1:SetValue(function(_,re) return re:IsMonsterEffect() and not re:GetHandler():IsRace(RACE_ZOMBIE) end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end