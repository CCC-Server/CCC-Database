--The Tower 0th Floor
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon Procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_ROCK),4,2,s.ovfilter,aux.Stringid(id,0),99,s.xyzop)
	c:EnableReviveLimit()
	--Gain the ATK/DEF of all "Zoodiac" monsters attached to itself
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c:IsType(TYPE_XYZ)  end)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	e2:SetValue(s.defval)
	c:RegisterEffect(e2)
	--search
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(function() return Duel.IsBattlePhase() end)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
	--Can attack directly
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e4)
end
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsSetCard(0x81e,lc,SUMMON_TYPE_XYZ,tp) and not c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,id)
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	return true
end
function s.atkfilter(c)
	return c:IsSetCard(0x81e) and c:GetAttack()>=0
end
function s.atkval(e,c)
	local g=c:GetOverlayGroup():Filter(s.atkfilter,nil)
	return g:GetSum(Card.GetAttack)
end
function s.deffilter(c)
	return c:IsSetCard(0x81e) and c:GetDefense()>=0
end
function s.defval(e,c)
	local g=c:GetOverlayGroup():Filter(s.atkfilter,nil)
	return g:GetSum(Card.GetDefense)
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local og=e:GetHandler():GetOverlayGroup()
	if chk==0 then return #og>0 end
	Duel.SendtoGrave(og,REASON_COST)
end
function s.thfilter(c)
	return c:IsCode(id-1) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end