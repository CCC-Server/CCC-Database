--光霊術師ライナ
--광령술사 라이너
Duel.LoadScript("archetype_crowel.lua")
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_CONTROL)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_BATTLE_CONFIRM)
	e1:SetCondition(s.btcon)
	e1:SetTarget(s.bttg)
	e1:SetOperation(s.btop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.mecon)
	e2:SetTarget(s.metg)
	e2:SetOperation(s.meop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.chcon)
	e3:SetTarget(s.chtg)
	e3:SetOperation(s.chop)
	c:RegisterEffect(e3)
end
function s.btcon(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	return bc and bc:IsControler(1-tp) and not Duel.IsExistingTarget(Card.HasFlagEffect,tp,LOCATION_MZONE,0,1,e:GetHandler(),id)
end
function s.bttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local bc=e:GetHandler():GetBattleTarget()
	if chk==0 then return bc:IsControler(1-tp) and bc:IsAttribute(ATTRIBUTE_LIGHT) and bc:IsControlerCanBeChanged() and bc:IsFaceup() end
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,bc,1,0,0)
end
function s.btop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=e:GetHandler():GetBattleTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and bc and not Duel.IsExistingTarget(Card.HasFlagEffect,tp,LOCATION_MZONE,0,1,e:GetHandler(),id) and not bc:IsImmuneToEffect(e) then
		bc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		c:SetCardTarget(bc)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_CONTROL)
		e1:SetValue(tp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetCondition(s.ctcon)
		bc:RegisterEffect(e1)
	end
end
function s.ctcon(e)
	local c=e:GetOwner()
	local h=e:GetHandler()
	return c:IsHasCardTarget(h)
end

function s.mecon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and rc:IsLocation(LOCATION_MZONE) and not Duel.IsExistingTarget(Card.HasFlagEffect,tp,LOCATION_MZONE,0,1,e:GetHandler(),id)
end
function s.metg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local rc=re:GetHandler()
	if chk==0 then return rc:IsControler(1-tp) and rc:IsAttribute(ATTRIBUTE_LIGHT) and rc:IsControlerCanBeChanged() and rc:IsFaceup() end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,rc,1,0,0)
end
function s.meop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and rc:IsLocation(LOCATION_MZONE) and rc:IsControler(1-tp) and not Duel.IsExistingTarget(Card.HasFlagEffect,tp,LOCATION_MZONE,0,1,e:GetHandler(),id) and not rc:IsImmuneToEffect(e) then
		rc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		c:SetCardTarget(rc)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_CONTROL)
		e1:SetValue(tp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetCondition(s.ctcon)
		rc:RegisterEffect(e1)
		Duel.NegateEffect(ev)
	end   
end

function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	local ch=ev-1
	local rc=re:GetHandler()
	if not (re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsArchetype(ARCHETYPE_SPIRITUAL_LIGHT_ART) and rp==tp) then return false end
	local ch_player,ch_eff=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_PLAYER,CHAININFO_TRIGGERING_EFFECT)
	if ch==0 then return end
	local ch_c=ch_eff:GetHandler()
	return ch_player==1-tp and (ch_c:IsAttribute(ATTRIBUTE_LIGHT) and ch_c:IsControlerCanBeChanged() and ch_c:IsLocation(LOCATION_MZONE) and ch_c:IsControlerCanBeChanged() and ch_c:IsFaceup()) and not Duel.IsExistingTarget(Card.HasFlagEffect,tp,LOCATION_MZONE,0,1,e:GetHandler(),id)
end
function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ch=ev-1
	local re=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_EFFECT)
	local rc=re:GetHandler()
	if chk==0 then return rc:IsControler(1-tp) and rc:IsControlerCanBeChanged() end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,rc,1,0,0)
end
function s.chop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ch=ev-1
	local re=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_EFFECT)
	local rc=re:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and rc:IsLocation(LOCATION_MZONE) and rc:IsControler(1-tp) and not Duel.IsExistingTarget(Card.HasFlagEffect,tp,LOCATION_MZONE,0,1,e:GetHandler(),id) and not rc:IsImmuneToEffect(e) then
		rc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		c:SetCardTarget(rc)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_CONTROL)
		e1:SetValue(tp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetCondition(s.ctcon)
		rc:RegisterEffect(e1)
		Duel.NegateEffect(ch)
	end   
end
