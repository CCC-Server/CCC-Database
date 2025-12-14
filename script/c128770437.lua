local s,id=GetID()

function s.initial_effect(c)
	-- Activate (once per turn by card name)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- ① Battle enhancement for "수왕권사" Xyz monster
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.bttg)
	e1:SetOperation(s.btop)
	c:RegisterEffect(e1)
end

-- --------------------
-- Target
-- --------------------
function s.btfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x770) and c:IsType(TYPE_XYZ)
end

function s.bttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE)
			and s.btfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.btfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.btfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

-- --------------------
-- Operation
-- --------------------
function s.btop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsFaceup() and tc:IsRelateToEffect(e)) then return end

	-- ① Cannot activate cards or effects during battle
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetCondition(s.actcon)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- ② Piercing damage
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e2)

	-- ③ Double battle damage
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e3:SetValue(aux.ChangeBattleDamage(1,DOUBLE_DAMAGE))
	e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e3)

	-- ④ Indestructible by battle
	local e4=Effect.CreateEffect(e:GetHandler())
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e4:SetValue(1)
	e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e4)

	-- ⑤ Destroy opponent monster after damage step
	local e5=Effect.CreateEffect(e:GetHandler())
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_DAMAGE_STEP_END)
	e5:SetCondition(s.descon)
	e5:SetOperation(s.desop)
	e5:SetLabelObject(tc)
	e5:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e5,tp)
end

-- --------------------
-- Conditions / Operations
-- --------------------
function s.actcon(e)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return a and a:IsSetCard(0x770)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if not tc or not tc:IsRelateToBattle() then return false end
	local bc=tc:GetBattleTarget()
	return bc~=nil
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if not tc then return end
	local bc=tc:GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		Duel.Destroy(bc,REASON_EFFECT)
	end
end
