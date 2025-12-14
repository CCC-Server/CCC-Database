local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	----------------------------------------------------
	-- ① 장착 (ATK +500)
	----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	----------------------------------------------------
	-- ② 효과 카피 (장착 상태에서만)
	----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.cpcon)
	e2:SetTarget(s.cptg)
	e2:SetOperation(s.cpop)
	c:RegisterEffect(e2)

	----------------------------------------------------
	-- ③ 1회 마함 무효
	----------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.negcon)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end


----------------------------------------------------
-- 공통 필터
----------------------------------------------------
function s.fusionfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION)
		and (c:IsSetCard(0x758) or c:IsSetCard(0x759))   -- '엘, 모델의 적합자' 또는 '엘' 융합
end

function s.modelfilter(c)
	return c:IsSetCard(0x759) and c:IsMonster() and c:IsAbleToGrave()
end


----------------------------------------------------
-- ① 장착 (ATK +500)
----------------------------------------------------
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.fusionfilter(chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.fusionfilter,tp,LOCATION_MZONE,0,1,nil) end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.fusionfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or not tc or not tc:IsRelateToEffect(e) then return end

	-- 장착
	if Duel.Equip(tp,c,tc,true) then
		-- ATK +500
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_EQUIP)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(500)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- ★ Equip Limit (자괴 방지)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_EQUIP_LIMIT)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		e2:SetValue(function(e,ec) return ec==tc end)
		c:RegisterEffect(e2)
	end
end


----------------------------------------------------
-- ② 이 카드 효과로 장착되어 있을 때만 발동
----------------------------------------------------
function s.cpcon(e)
	return e:GetHandler():GetEquipTarget() ~= nil
end

function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.modelfilter,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil)
	end
end

function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.modelfilter,tp,LOCATION_DECK+LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()

	if tc and Duel.SendtoGrave(tc,REASON_EFFECT)>0 then
		local code=tc:GetOriginalCode()

		-- 이름 변경
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- 효과 복사
		c:CopyEffect(code,RESET_EVENT|RESETS_STANDARD)
	end
end


----------------------------------------------------
-- ③ 상대 마/함 1회 무효
----------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()
	if not ec then return false end

	-- 장착 대상이 '엘, 모델의 적합자' 또는 '엘' 융합일 때만
	if not (ec:IsSetCard(0x758) or ec:IsSetCard(0x759)) then return false end

	if ep==tp then return false end
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and Duel.IsChainDisablable(ev)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end

