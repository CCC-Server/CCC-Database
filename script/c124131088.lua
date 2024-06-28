--퍼프커스 퓨전
local s,id=GetID()
function s.initial_effect(c)
	local e1=Fusion.CreateSummonEff(c,nil,nil,s.fextra)
	c:RegisterEffect(e1)
	--salvage
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_series={0x135}
function s.chkfilter(c,tp,fc)
	return c:IsSetCard(0x81c,fc,SUMMON_TYPE_FUSION,tp) and c:IsControler(tp)
end
function s.fcheck(tp,sg,fc,mg)
	if sg:IsExists(Card.IsControler,1,nil,1-tp) then 
		return sg:IsExists(s.chkfilter,1,nil,tp,fc) end
	return true
end
function s.fextra(e,tp,mg)
	if mg:IsExists(Card.IsSetCard,1,nil,0x135,nil,SUMMON_TYPE_FUSION,tp) then
		local g=Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsFaceup,Card.IsMonster,Card.IsAbleToGrave),tp,0,LOCATION_MZONE,nil)
		if g and #g>0 then
			return g,s.fcheck
		end
	end
	return nil
end
function s.thfilter(c)
	return c:IsSetCard(0x81c) and c:IsAbleToDeckAsCost() and aux.SpElimFilter(c,true)
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE|LOCATION_MZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE|LOCATION_MZONE,0,1,1,e:GetHandler())
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end
