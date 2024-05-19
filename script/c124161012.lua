--SunLightshape's Shrine
local s,id=GetID()
function s.initial_effect(c)
	--activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--effect 1
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(_,c) return c:IsSetCard(0xf20) end)
	e1:SetValue(s.val1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	--effect 2
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_CONFIRM)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.con2)
	e3:SetTarget(s.tg2)
	e3:SetOperation(s.op2)
	c:RegisterEffect(e3)
	--effect 3
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_TRIGGER)
	e4:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(0,LOCATION_SZONE)
	e4:SetCondition(s.con3)
	e4:SetTarget(s.tg3)
	c:RegisterEffect(e4)
end

--effect 1
function s.val1filter(c)
	return c:IsPublic()  
end

function s.val1(e,c)
	return Duel.GetMatchingGroupCount(s.val1filter,e:GetHandlerPlayer(),LOCATION_HAND,0,nil)*300
end

--effect 2
function s.con2filter(c,tp)
	return c:IsSetCard(0xf20) and c:IsControler(tp) and c:IsLocation(LOCATION_HAND)
end

function s.con2(e,tp,eg)
	return eg:IsExists(s.con2filter,1,nil,tp)
end

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>2 end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.op2filter(c)
	return c:IsSetCard(0xf20) and not c:IsType(TYPE_FIELD) and c:IsAbleToHand()
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
	Duel.ConfirmDecktop(tp,3)
	local dt=Duel.GetDecktopGroup(tp,3)
	if #dt>0 and dt:IsExists(s.op2filter,1,nil)and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=dt:FilterSelect(tp,s.op2filter,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
	Duel.ShuffleDeck(tp)
end

--effect 3
function s.con3filter(c)
	return c:IsPublic() and c:IsSetCard(0xf20)
end

function s.con3(e)
	local tp=e:GetHandler():GetControler()
	return Duel.GetMatchingGroupCount(s.con3filter,tp,LOCATION_HAND,0,nil)>0
end

function s.tg3(e,c)
	return c:IsFacedown()
end
