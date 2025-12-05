--Mist Valley Commander Thunder Lord
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon procedure
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,SET_MIST_VALLEY),1,99)
	c:EnableReviveLimit()
	-- (1) Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	-- (2) Quick Effect: bounce 1 yours + 1 opponent's, then you can activate 1 "Mist Valley" S/T from hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) -- (2) 효과 명칭 1턴 1번
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	-- (3) Each time card(s) on the field return to the hand, gain 500 ATK for each
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

--------------------------------
-- 공통: 비-WIND 특수 소환 제한
--------------------------------
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsAttribute(ATTRIBUTE_WIND)
end

--------------------------------
-- (2) Bounce + Mist Valley S/T 발동
--------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and chkc:IsControler(tp) and chkc:IsAbleToHand()
	end
	if chk==0 then
		-- 내가 컨트롤하는 카드 1장, 상대 필드 카드 1장이 있어야 함
		return Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,1-tp,LOCATION_ONFIELD)
end

-- 손에서 발동 가능한 "Mist Valley" 마/함
function s.mvst_handfilter(c)
	return c:IsSetCard(SET_MIST_VALLEY) and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:GetActivateEffect()~=nil
end

-- "Mist Valley" 마/함 1장 손에서 즉시 발동 처리
function s.mv_activate_from_hand(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local g=Duel.GetMatchingGroup(s.mvst_handfilter,tp,LOCATION_HAND,0,nil)
	if #g==0 then return end
	-- 발동 여부 선택
	if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ACTIVATE)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if not tc then return end
	Duel.Hint(HINT_CARD,0,tc:GetCode())
	local te=tc:GetActivateEffect()
	if not te then return end
	local condition=te:GetCondition()
	local cost=te:GetCost()
	local target=te:GetTarget()
	local operation=te:GetOperation()
	-- 간단 조건 체크 (완벽하진 않지만 기본적인 조건만 확인)
	if condition and not condition(te,tp,eg,ep,ev,re,r,rp) then return end
	-- 필드 마법 처리
	if tc:IsType(TYPE_FIELD) then
		local fc=Duel.GetFieldCard(tp,LOCATION_SZONE,5)
		if fc~=nil then
			Duel.SendtoGrave(fc,REASON_RULE)
		end
		fc=Duel.GetFieldCard(1-tp,LOCATION_SZONE,5)
		if fc~=nil and Duel.SendtoGrave(fc,REASON_RULE)==0 then
			Duel.SendtoGrave(tc,REASON_RULE)
			return
		end
	end
	-- 마/함 존으로 이동시키면서 발동
	Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	tc:CreateEffectRelation(te)
	if cost then cost(te,tp,eg,ep,ev,re,r,rp,1) end
	if target then target(te,tp,eg,ep,ev,re,r,rp,1) end
	Duel.BreakEffect()
	local g2=Duel.GetMatchingGroup(Card.IsOnField,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	for sc in aux.Next(g2) do
		sc:CreateEffectRelation(te)
	end
	if operation then operation(te,tp,eg,ep,ev,re,r,rp) end
	tc:ReleaseEffectRelation(te)
	for sc in aux.Next(g2) do
		sc:ReleaseEffectRelation(te)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	-- 상대 필드 카드 선택
	if Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g2=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g2==0 then return end
	g2:AddCard(tc)
	-- 동시에 패로 되돌리기
	local ct=Duel.SendtoHand(g2,nil,REASON_EFFECT)
	if ct<=0 then
		-- 그래도 특소 제한은 걸림 (효과를 "발동"했으므로)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		return
	end
	-- Mist Valley 마/함 즉시 발동 시도
	s.mv_activate_from_hand(e,tp,eg,ep,ev,re,r,rp)
	-- 이 턴 동안 비-WIND 특수 소환 불가
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--------------------------------
-- (3) 필드의 카드가 패로 돌아갈 때마다 ATK 상승
--------------------------------
function s.atkfilter(c)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() then return end
	local ct=eg:FilterCount(s.atkfilter,nil)
	if ct<=0 then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(ct*500)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	c:RegisterEffect(e1)
end
