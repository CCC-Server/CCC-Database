local s,id=GetID()
function s.initial_effect(c)

	----------------------------------------------------
	-- Effect ①: Activate → Target 1 opponent face-up card & negate
	----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	----------------------------------------------------
	-- Effect ②: If non-QP Spell Librarian Spell resolved → Set self from GY
	----------------------------------------------------
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,1))
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_CHAINING)
e2:SetRange(LOCATION_GRAVE)
e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
e2:SetCountLimit(1,id+100)
e2:SetCondition(s.setcon)
e2:SetTarget(s.settg)
e2:SetOperation(s.setop)
c:RegisterEffect(e2)
end


----------------------------------------------------
-- Activation restriction (No NS / SS this turn)
----------------------------------------------------
function s.actcon(e,tp)
	return Duel.GetActivityCount(tp,ACTIVITY_SUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0
end


----------------------------------------------------
-- Effect ①: Target & Negate
----------------------------------------------------
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_ONFIELD)
			and s.negfilter(chkc)
	end
	if chk==0 then 
		return Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end


----------------------------------------------------
-- Effect ②: Set self from GY if non-QP Spell Librarian Spell resolves
----------------------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then return false end
	local rc=re:GetHandler()
	return rc and rc:IsControler(tp)
		and rc:IsSetCard(0x768)	   -- "스펠 라이브러리언"
		and rc:IsType(TYPE_SPELL)
end

-- Target: This card in your GY
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc==c end
	if chk==0 then
		return c:IsRelateToEffect(e) and c:IsSSetable()
	end
	Duel.SetTargetCard(c)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end

-- Operation: Set this card & make it banish when it leaves field
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.SSet(tp,c)

	-- Banish if it leaves the field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
	e1:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e1)
end