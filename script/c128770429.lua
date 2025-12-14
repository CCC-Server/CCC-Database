local s,id=GetID()

function s.initial_effect(c)
	-- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x770),4,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
	c:EnableReviveLimit()

	-- ① Can attack all opponent's monsters once each
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- ② During the Battle Phase, unaffected by effects that do not target this card
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)

	-- ③ Gain 700 ATK when it destroys a monster by battle and sends it to the GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(aux.bdocon)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- ④ End of Battle Phase: Special Summon "수왕권사-백토" and return this card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
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
-- ② Immunity condition/value
-- --------------------
function s.immcon(e)
	return Duel.IsBattlePhase()
end

function s.immval(e,te)
	local c=e:GetHandler()
	if te:GetOwnerPlayer()==c:GetControler() then return false end
	-- If the effect does not target this card, this card is unaffected
	if not te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		return true
	end
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	return not (tg and tg:IsContains(c))
end

-- --------------------
-- ③ ATK up
-- --------------------
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(700)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
end

-- --------------------
-- ④ Return and Special Summon "수왕권사-백토"
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
