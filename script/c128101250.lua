--Holophantasy Field – Reactive Sanctum (Custom)
local s,id=GetID()
function s.initial_effect(c)
	--Activate (Field Spell)
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--① If YOU Synchro Summon a "Holophantasy" monster: target 1 card your opponent controls; destroy it (HOPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	--② If this card is sent to the GY: place 1 "Holophantasy" Field Spell from your hand/Deck to your Field; 
	--   for the rest of this turn, you can only Special Summon Synchro monsters from the Extra Deck (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.fztg)
	e2:SetOperation(s.fzop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc44}

-- ========= ① 조건/처리 =========
function s.synfilter(c,tp)
	return c:IsSummonType(SUMMON_TYPE_SYNCHRO) and c:IsControler(tp) and c:IsSetCard(0xc44)
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.synfilter,1,nil,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-- ========= ② GY 트리거: 배치 + 엑스트라 제한 =========
function s.fspellfilter(c)
	return c:IsSetCard(0xc44) and c:IsType(TYPE_FIELD)
end
function s.fztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fspellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
	end
	-- MoveToField는 별도 opinfo 불필요
end
function s.fzop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) -- "필드 마법을 선택"
	local g=Duel.SelectMatchingCard(tp,s.fspellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and not tc:IsForbidden() then
		-- 필드존에 '놓기'(activate 아님). 기존 필드는 룰에 따라 처리됨.
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	end
	-- 그 턴, Extra에서 Synchro 이외 특소 불가
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,4)) -- "이 턴, 엑스트라 덱에서 싱크로 이외는 특수 소환할 수 없다."
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,sc) return sc:IsLocation(LOCATION_EXTRA) and not sc:IsType(TYPE_SYNCHRO) end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	-- Clock Lizard check
	aux.addTempLizardCheck(c,tp,function(e,sc) return not sc:IsType(TYPE_SYNCHRO) end)
end
