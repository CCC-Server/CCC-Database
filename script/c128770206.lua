-- 엘, 모델의 적합자 + 모델O (개정판)
local s,id=GetID()
local CODE_FITTER=128770189
local CODE_MODELO=128770197

---------------------------------------------
-- 초기 설정
---------------------------------------------
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CODE_FITTER,CODE_MODELO)

	-----------------------------------------------------
	-- ① 특수 소환 제한 : 융합 또는 고유 특소만
	-----------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-----------------------------------------------------
	-- ② 고유 특수 소환 절차
	-----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-----------------------------------------------------
	-- ③ SS 성공 시 : 묘지의 ‘모델’ 카드 최대 3장 장착
	-----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.eq1con)
	e2:SetTarget(s.eqtg1)
	e2:SetOperation(s.eqop1)
	c:RegisterEffect(e2)

	-----------------------------------------------------
	-- ④ 메인페이즈 양쪽 : 묘지 모델 몬스터 1장 장착
	-----------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_EQUIP)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.eqcon2)
	e3:SetTarget(s.eqtg2)
	e3:SetOperation(s.eqop2)
	c:RegisterEffect(e3)

	-----------------------------------------------------
	-- ⑤ 묘지의 "엘" 융합 제외 → 효과 복사
	-----------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})
	e4:SetTarget(s.cptg)
	e4:SetOperation(s.cpop)
	c:RegisterEffect(e4)
end

---------------------------------------------
-- ① 소환 제한 : 융합 또는 고유 소환만
---------------------------------------------
function s.splimit(e,se,sp,st)
	if (st & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION then
		return true
	end
	return se:IsHasType(EFFECT_SPSUMMON_PROC)
end

---------------------------------------------
-- ② 고유 특소
---------------------------------------------
function s.spfilter(c)
	return c:IsCode(CODE_FITTER,CODE_MODELO)
		and c:IsAbleToGraveAsCost()
		and (c:IsLocation(LOCATION_HAND)
		or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()))
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(function(c) return c:IsCode(CODE_FITTER) and s.spfilter(c) end,
			tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(function(c) return c:IsCode(CODE_MODELO) and s.spfilter(c) end,
			tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,function(c) return c:IsCode(CODE_FITTER) and s.spfilter(c) end,
			tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,function(c) return c:IsCode(CODE_MODELO) and s.spfilter(c) end,
			tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	g1:Merge(g2)
	Duel.SendtoGrave(g1,REASON_COST)
end

---------------------------------------------
-- ③ SS 성공 → 묘지 모델 카드 최대 3장 장착
---------------------------------------------
function s.eq1con(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.model_filter(c)
	return c:IsSetCard(0x759)
end

function s.eqtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.model_filter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.model_filter,tp,LOCATION_GRAVE,0,1,3,nil)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,#g,0,0)
end

function s.eqop1(e,tp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	for tc in aux.Next(g) do
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
		if Duel.Equip(tp,tc,c,true) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_COPY_INHERIT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(function(e,ec) return ec==c end)
			tc:RegisterEffect(e1)
		end
	end
end

---------------------------------------------
-- ④ 메인페이즈 양쪽 → 묘지 모델 몬스터 장착
---------------------------------------------
function s.eqcon2(e)
	return Duel.IsMainPhase()
end

function s.eqmonster(c)
	return c:IsSetCard(0x759) and c:IsMonster()
end

function s.eqtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE)
			and chkc:IsControler(tp)
			and s.eqmonster(chkc)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(s.eqmonster,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqmonster,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end

function s.eqop2(e,tp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Equip(tp,tc,c,true) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_COPY_INHERIT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(function(e,ec) return ec==c end)
		tc:RegisterEffect(e1)
	end
end

---------------------------------------------
-- ⑤ 묘지의 "엘" 융합 제외 → 효과 복사
---------------------------------------------
function s.copyfilter(c)
	return c:IsSetCard(0x758) and c:IsType(TYPE_FUSION) and c:IsAbleToRemove()
end

function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	e:SetLabelObject(g:GetFirst())
end

function s.cpop(e,tp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()
	if not tc then return end
	c:CopyEffect(tc:GetOriginalCodeRule(),RESET_EVENT+RESETS_STANDARD_DISABLE,1)
end
