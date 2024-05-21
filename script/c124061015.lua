--火霊術師ヒータ
Duel.LoadScript("strings.lua") --구현 완료되면 삭제
local s,id=GetID()
function s.initial_effect(c)
	--Spell/Traps can be activated from the hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(s.acttg)
	e1:SetCondition(s.actcon)
	e1:SetValue(s.actvalue)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e2)
	--Spell/Traps can be activated from the Deck
	c:UnimplementedPartially() --구현 완료되면 삭제
	--[[
	local e3=e1:Clone()
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCode(EFFECT_ACTIVATABLE_RANGE)
	e3:SetTargetRange(LOCATION_DECK,0)
	c:RegisterEffect(e3)
	--]]
	--Activation cost
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_ACTIVATE_COST)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetTargetRange(1,0)
	e4:SetTarget(s.costtg)
	e4:SetCost(s.costcost)
	e4:SetOperation(s.costop)
	c:RegisterEffect(e4)
	--Change Control (Battle)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_CONTROL)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_BATTLE_CONFIRM)
	e5:SetTarget(s.cctg1)
	e5:SetOperation(s.ccop1)
	c:RegisterEffect(e5)
	--Change Control (Effect)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_CHAIN_SOLVING)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.cctg2)
	e6:SetOperation(s.ccop2)
	c:RegisterEffect(e6)
end
s.listed_series={SET_SPIRITUAL_FIRE_ART} --◆
--Spell/Traps can be activated from the hand or Deck
s.acttg=aux.TargetBoolFunction(Card.IsSetCard,SET_SPIRITUAL_FIRE_ART) --◆
function s.actcon(e)
	return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),LOCATION_HAND,0)>0
end
function s.actvalue(e,rc,re)
	re:GetHandler():RegisterFlagEffect(id,RESET_CHAIN,0,0,e:GetHandler():GetFieldID())
end
--Activation cost
function s.costtg(e,te,tp)
	local tc=te:GetHandler()
	return tc:GetFlagEffect(id)>0 and tc:GetFlagEffectLabel(id)==e:GetHandler():GetFieldID()
end
function s.costcost(e,te,tp)
	if te:GetHandler():GetLocation()==LOCATION_DECK then
		e:SetLabel(1)
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil,REASON_COST+REASON_DISCARD)
	else
		e:SetLabel(0)
		return true
	end
end
function s.costop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	if e:GetLabel()>0 then
		e:SetLabel(0)
		Duel.DiscardHand(tp,nil,1,1,REASON_COST+REASON_DISCARD)
	end
end
--Change Control (Battle)
function s.cctg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then
		return c:IsFaceup()
			and not (Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,c,c) or c:IsRelateToCard(c))
			and bc and bc:IsControlerCanBeChanged()
			and bc:IsFaceup() and bc:IsAttribute(ATTRIBUTE_FIRE) --◆
	end
	bc:CreateEffectRelation(e)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,bc,1,tp,0)
end
function s.ccop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if c:IsFaceup() and c:IsRelateToEffect(e)
		and not (Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,c,c) or c:IsRelateToCard(c))
		and bc and bc:IsRelateToEffect(e) and bc:IsControlerCanBeChanged()
		and not bc:IsImmuneToEffect(e) then
			local ctrl=bc:GetControler()
			c:CreateRelation(bc,RESET_EVENT|RESETS_STANDARD)
			bc:CreateRelation(c,RESET_EVENT|RESETS_STANDARD)
			local eff=Effect.CreateEffect(c)
			eff:SetType(EFFECT_TYPE_SINGLE)
			eff:SetCode(EFFECT_SET_CONTROL)
			eff:SetValue(tp)
			eff:SetReset(RESET_EVENT+RESETS_STANDARD)
			eff:SetCondition(s.ctcon)
			bc:RegisterEffect(eff)
	end
end
function s.ctfilter(c1,c2)
	return c1:IsRelateToCard(c2) and c2:IsRelateToCard(c1)
end
function s.ctcon(e)
	return s.ctfilter(e:GetOwner(),e:GetHandler())
end
--Change Control (Effect)
function s.cctg2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	return not (Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,c,c) or c:IsRelateToCard(c))
		and rp~=tp and re:IsActiveType(TYPE_MONSTER)
		and rc:IsControlerCanBeChanged()
		and rc:IsFaceup() and rc:IsAttribute(ATTRIBUTE_FIRE) --◆
		and Duel.IsChainDisablable(ev)
end
function s.ccop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if Duel.SelectEffectYesNo(tp,c) then
		Duel.Hint(HINT_CARD,0,id)
		if not rc:IsImmuneToEffect(e) and rc:IsRelateToEffect(re) then
			c:CreateRelation(rc,RESET_EVENT|RESETS_STANDARD)
			rc:CreateRelation(c,RESET_EVENT|RESETS_STANDARD)
			local eff=Effect.CreateEffect(c)
			eff:SetType(EFFECT_TYPE_SINGLE)
			eff:SetCode(EFFECT_SET_CONTROL)
			eff:SetValue(tp)
			eff:SetReset(RESET_EVENT+RESETS_STANDARD)
			eff:SetCondition(s.ctcon)
			rc:RegisterEffect(eff)
			Duel.NegateEffect(ev)
		end
	end
end
