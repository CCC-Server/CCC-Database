--동물귀무녀 센코
--けもみみこせんこ
--Mimiko Senko
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xda0),3,2,nil,nil,7)
	--Attach 1 card from GY to this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)

	e1:SetTarget(s.atttg)
	e1:SetOperation(s.attop)
	c:RegisterEffect(e1)

	--Change 1 monster to face-down Defense Position
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
			e3:SetCountLimit(1,{id,1})
	e3:SetHintTiming(TIMING_MAIN_END,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCondition(s.con1)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

--Part of "Mimiko" archetype
s.listed_series={0xda0}

function s.con1()
	return Duel.IsMainPhase()
end


function s.filter(c)
	return not c:IsType(TYPE_TOKEN) and c:IsAbleToChangeControler()
end

function s.atttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE|LOCATION_ONFIELD) and chkc:IsControler(1-tp) and s.filter(chkc) end
	if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) and Duel.IsExistingTarget(s.filter,tp,0,LOCATION_GRAVE|LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_GRAVE|LOCATION_ONFIELD,1,1,nil)
end

function s.attop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Overlay(c,tc,true)
	end
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil,e)
	if chk==0 then return #g>0 and c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	local rt=math.min(#g,c:GetOverlayCount())
	local ct=c:RemoveOverlayCard(tp,1,rt,REASON_COST)
	e:SetLabel(ct)
end

function s.setfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end
	if chk==0 then return true end
	local ct=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_MZONE,LOCATION_MZONE,ct,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,#g,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)
	end
end
