local s,id=GetID()
local KOUKO_CODE=128770416 -- "수왕권사-황호"

function s.initial_effect(c)
	-- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x770),2,2)
	c:EnableReviveLimit()

	-- Overlay Xyz Summon using "수왕권사-황호"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.ovcon)
	e0:SetOperation(s.ovop)
	c:RegisterEffect(e0)

	-- ① Cannot be destroyed by opponent's card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.indoval)
	c:RegisterEffect(e1)

	-- ② Change battle position (no Flip effect)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.postg)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)

	-- ③ Destroy Spell/Trap after damage calculation
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DAMAGE_CALCULATED)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)

	-- ④ End of Battle Phase: Special Summon "수왕권사-황호" and return this card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.retcon)
	e4:SetOperation(s.retop)
	c:RegisterEffect(e4)
end

-- ====================
-- Overlay Xyz Summon
-- ====================
function s.ovcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.ovfilter(c,tp)
	return c:IsFaceup()
		and c:IsCode(KOUKO_CODE)
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

-- ====================
-- ② Change position
-- ====================
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.ChangePosition(
			tc,
			POS_FACEUP_DEFENSE,
			POS_FACEUP_ATTACK,
			POS_FACEDOWN_DEFENSE,
			POS_FACEDOWN_ATTACK
		)
	end
end

-- ====================
-- ③ Destroy Spell/Trap
-- ====================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler()==Duel.GetAttacker()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(1-tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_SZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_SZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-- ====================
-- ④ Return & Special Summon
-- ====================
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()>0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	local g=c:GetOverlayGroup():Filter(Card.IsCode,nil,KOUKO_CODE)
	if #g==0 then return end

	local tc=g:GetFirst()
	c:RemoveOverlayCard(tp,1,1,REASON_EFFECT)
	Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end
