--킨더가든과 기적의 동아줄
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetCountLimit(1,{id,1})
	e5:SetOperation(s.doublebattlephase)
	c:RegisterEffect(e5)
end

function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(0xdc1) and c:IsMonsterCard()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_ONFIELD,0,2,nil) and Duel.GetMatchingGroupCount(aux.TRUE,tp,0,LOCATION_ONFIELD,nil,e,tp)>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_ONFIELD,0,2,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end
	Duel.SendtoHand(g,nil,REASON_EFFECT)
	local st=Duel.GetMatchingGroup(Card.IsSpellTrap,tp,0,LOCATION_ONFIELD,nil,e,tp)
	local mon=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_ONFIELD,nil,e,tp)
	local op=-1
	if #st>0 and #mon>0 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,0))
	elseif #st>0 then
		op=0
	elseif #mon>0 then
		op=1
	end
	if op==0 then
		Duel.Destroy(st,REASON_EFFECT)
	end
	if op==1 then
		Duel.Destroy(mon,REASON_EFFECT)
	end
end
function s.doublebattlephase(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,EFFECT_BP_TWICE) then return end
	local turn_ct=Duel.GetTurnCount()
	local ct=Duel.IsTurnPlayer(tp) and Duel.IsBattlePhase() and 2 or 1
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_BP_TWICE)
	e1:SetTargetRange(1,0)
	e1:SetValue(1)
	e1:SetCondition(function() return ct==1 or Duel.GetTurnCount()~=turn_ct end)
	e1:SetReset(RESET_PHASE|PHASE_BATTLE|RESET_SELF_TURN,ct)
	Duel.RegisterEffect(e1,tp)
end