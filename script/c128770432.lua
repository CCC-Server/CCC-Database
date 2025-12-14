local s,id=GetID()
local CHUNGHWANG_CODE=128770422 -- "수왕권사-충황"

function s.initial_effect(c)
	-- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x770),2,2)
	c:EnableReviveLimit()

	-- Overlay Xyz Summon using "수왕권사-충황"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.ovcon)
	e0:SetOperation(s.ovop)
	c:RegisterEffect(e0)

	-- ① Can attack while in Defense Position, using DEF as ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DEFENSE_ATTACK)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- ② Indestructible by battle and card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2b:SetValue(1)
	c:RegisterEffect(e2b)

	-- ③ Negate and destroy opponent monster effect during Battle Phase
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- ④ End of Battle Phase: Special Summon "수왕권사-충황" and return this card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.retcon)
	e4:SetOperation(s.retop)
	c:RegisterEffect(e4)
end

-- --------------------
-- Overlay Xyz Summon
-- --------------------
function s.ovcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.ovfilter(c,tp)
	return c:IsFaceup() and c:IsCode(CHUNGHWANG_CODE)
		and c:IsCanBeXyzMaterial(nil,tp)
end

function s.ovop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local tc=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil,tp):GetFirst()
	if not tc then return end
	local mg=tc:GetOverlayGroup()
	if #mg>0 then
		Duel.SendtoGrave(mg,REASON_RULE)
	end
	c:SetMaterial(Group.FromCards(tc))
	Duel.Overlay(c,Group.FromCards(tc))
end

-- --------------------
-- ③ Negate condition
-- --------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsBattlePhase() then return false end
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- --------------------
-- ④ Return and Special Summon "수왕권사-충황"
-- --------------------
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()>0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=c:GetOverlayGroup():Filter(Card.IsCode,nil,CHUNGHWANG_CODE)
	if #g==0 then return end
	local tc=g:GetFirst()
	c:RemoveOverlayCard(tp,tc,tc,REASON_EFFECT)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end
