--십이수의 일학
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Link Summon procedure
	Link.AddProcedure(c,s.matfilter,1,1)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function()return Duel.IsMainPhase() or Duel.IsBattlePhase() end)
	e1:SetCost(s.cost)
	e1:SetTarget(s.efftg)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
end
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0xf1,lc,sumtype,tp) and not c:IsType(TYPE_LINK,lc,sumtype,tp)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,2,REASON_COST)
end
function s.xfilter(c)
	return c:IsType(TYPE_XYZ) and c:IsFaceup()
end
function s.xdfilter(c)
	return c:IsSetCard(0xf1)
end
function s.matfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf1) and c:IsCanBeXyzMaterial()
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	local b1=Duel.IsExistingMatchingCard(s.xfilter,tp,LOCATION_MZONE,0,1,nil) and Duel.IsExistingMatchingCard(s.xdfilter,tp,LOCATION_HAND+ LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(Card.IsXyzSummonable,tp,LOCATION_EXTRA,0,1,nil,nil,mg)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)})
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(0)
	elseif op==2 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	end
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()==1 then
		local g=Duel.GetMatchingGroup(s.xfilter,tp,LOCATION_MZONE,0,nil)
		local xg=Duel.GetMatchingGroup(s.xdfilter,tp,LOCATION_HAND+ LOCATION_DECK,0,nil)
		if #g==0 or #xg==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local sg=Duel.SelectMatchingCard(tp,s.xfilter,tp,LOCATION_MZONE,0,1,1,nil,nil):GetFirst()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local xsg=Duel.SelectMatchingCard(tp,s.xdfilter,tp,LOCATION_HAND+ LOCATION_DECK,0,1,1,nil,nil):GetFirst()
		Duel.Overlay(sg,xsg,true)
	else
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
		if #mg==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local xc=Duel.SelectMatchingCard(tp,Card.IsXyzSummonable,tp,LOCATION_EXTRA,0,1,1,nil,nil,mg):GetFirst()
		if xc then
			Duel.XyzSummon(tp,xc,nil,mg,1,99)
		end
	end
end