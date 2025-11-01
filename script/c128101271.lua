--Buster Deity Dragon (가칭)
local s,id=GetID()
local CARD_ASSAULT_MODE=80280737 -- "버스터 모드"

function s.initial_effect(c)
	c:EnableReviveLimit()
	--Synchro Summon Procedure
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,Synchro.NonTunerEx(Card.IsType,TYPE_SYNCHRO),1,99)
	
	--① Set "Buster Mode" or its named S/T from GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	
	--② Change name and negate
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.nametg)
	e2:SetOperation(s.nameop)
	c:RegisterEffect(e2)
	
	--③ Release replace
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_RELEASE_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.reptg)
	e3:SetValue(1)
	c:RegisterEffect(e3)
end

-- For reference
s.listed_names={CARD_ASSAULT_MODE}
s.listed_series={0x2012}

---------------------------------------------------------------
-- ① 싱크로 소환 성공 시 묘지 세트
---------------------------------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.setfilter(c)
	return (c:IsCode(CARD_ASSAULT_MODE) or (c:IsSpellTrap() and c:ListsCode(CARD_ASSAULT_MODE)))
		and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.setfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SSet(tp,tc)
		Duel.ConfirmCards(1-tp,tc)
	end
end

---------------------------------------------------------------
-- ② 서로의 턴 / 대상 몬스터 이름 변경 + 효과 무효
---------------------------------------------------------------
function s.nametg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		and Duel.IsExistingMatchingCard(s.syncfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.syncfilter(c)
	return c:IsType(TYPE_SYNCHRO)
end
function s.nameop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	-- 엑덱 싱크로 공개
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.syncfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g==0 then return end
	local sc=g:GetFirst()
	Duel.ConfirmCards(1-tp,sc)
	local code=sc:GetCode()
	-- 이름 변경
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(code)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
	-- 효과 무효
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_DISABLE_EFFECT)
	tc:RegisterEffect(e3)
end

---------------------------------------------------------------
-- ③ 자신 카드 효과의 릴리스 대체
---------------------------------------------------------------
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsControler(1-tp) and c:IsReleasableByEffect()
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.repfilter,tp,0,LOCATION_MZONE,1,nil,tp) end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,0,LOCATION_MZONE,1,1,nil,tp)
		if #g>0 then
			Duel.Release(g,REASON_EFFECT+REASON_REPLACE)
			return true
		end
	end
	return false
end
