local s,id=GetID()

function s.initial_effect(c)
	-- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x770),4,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
	c:EnableReviveLimit()

	-- ① Inflict piercing battle damage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e1)

	-- ② Set DEF to 0
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.bpcon)
	e2:SetTarget(s.deftg)
	e2:SetOperation(s.defop)
	c:RegisterEffect(e2)

	-- ③ Inflict damage when destroying DEF 0 monster
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.damcon)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)

	-- ④ End of Battle Phase: Special Summon "수왕권사-분서" and return this card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.retcon)
	e4:SetOperation(s.retop)
	c:RegisterEffect(e4)
end

-- --------------------
-- Overlay Xyz Summon
-- --------------------
function s.ovfilter(c,tp,xyzc)
	return c:IsSummonCode(xyzc,SUMMON_TYPE_XYZ,tp,id-10) and c:IsFaceup()
end

function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	return true
end

-- --------------------
-- ② Battle Phase check
-- --------------------
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

-- --------------------
-- ② DEF to 0
-- --------------------
function s.deftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(1-tp)
			and chkc:IsPosition(POS_FACEUP_DEFENSE)
	end
	if chk==0 then
		return Duel.IsExistingTarget(
			function(c) return c:IsFaceup() and c:IsDefensePos() end,
			tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,
		function(c) return c:IsFaceup() and c:IsDefensePos() end,
		tp,0,LOCATION_MZONE,1,1,nil)
end

function s.defop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_DEFENSE)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

-- --------------------
-- ③ Damage condition
-- --------------------
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsDefense(0)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	if not bc then return end
	local val=0
	if bc:IsType(TYPE_XYZ) then
		val=bc:GetRank()*200
	else
		val=bc:GetLevel()*200
	end
	if val>0 then
		Duel.Damage(1-tp,val,REASON_EFFECT)
	end
end

-- --------------------
-- ④ Return and Special Summon "수왕권사-분서"
-- --------------------
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()>0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=c:GetOverlayGroup():Filter(Card.IsCode,nil,id-10)
	if #g==0 then return end
	local tc=g:GetFirst()
	c:RemoveOverlayCard(tp,tc,tc,REASON_EFFECT)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end
