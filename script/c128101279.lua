--Borrel Overburst Dragon
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Link Summon procedure (2+ Effect Monsters, including a DARK Dragon)
	Link.AddProcedure(c,s.matfilter,2,nil,s.matcheck)

	--① Cannot be destroyed by battle or card effects
	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_SINGLE)
	e1a:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1a:SetRange(LOCATION_MZONE)
	e1a:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1a:SetValue(1)
	c:RegisterEffect(e1a)
	local e1b=e1a:Clone()
	e1b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e1b)

	--② When a monster is Special Summoned: Destroy 1 opponent's card, then deal damage equal to its original ATK if it was a monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--③ When this card declares an attack on a face-up monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.atkcon)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_BORREL,SET_ROKKET}

-----------------------------------------------------
-- Material filter (Effect Monsters, including DARK Dragon)
-----------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
	return c:IsType(TYPE_EFFECT,lc,sumtype,tp)
end
function s.matcheck(g,lc,sumtype,tp)
	return g:IsExists(s.darkdragon,1,nil,lc,sumtype,tp)
end
function s.darkdragon(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp) and c:IsRace(RACE_DRAGON,lc,sumtype,tp)
end

-----------------------------------------------------
-- ② Destroy + Burn
-----------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local atk=tc:IsMonster() and tc:GetBaseAttack() or 0
		if Duel.Destroy(tc,REASON_EFFECT)>0 and atk>0 then
			Duel.Damage(1-tp,atk,REASON_EFFECT)
		end
	end
end

-----------------------------------------------------
-- ③ Attack declaration power modification
-----------------------------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttackTarget()
	return a and a:IsFaceup() and a:IsControler(1-tp)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttackTarget()
	if not (c:IsRelateToEffect(e) and c:IsFaceup() and a and a:IsRelateToBattle()) then return end
	local atk=a:GetAttack()
	if atk<=0 then return end
	-- Boost this card
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(math.floor(atk/2))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
	-- Halve target's ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_ATTACK_FINAL)
	e2:SetValue(math.floor(atk/2))
	e2:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
	a:RegisterEffect(e2)
end
