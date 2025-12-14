-- 엘, 모델의 적합자 + 모델P
local s,id=GetID()
local CODE_FITTER = 128770189
local CODE_MODELP = 128770195

function s.initial_effect(c)
	---------------------------------------------------------
	-- 융합 소환
	---------------------------------------------------------
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CODE_FITTER,CODE_MODELP)

	---------------------------------------------------------
	-- 특소 제한 : 융합 또는 고유 특소만
	---------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	---------------------------------------------------------
	-- 고유 특수 소환
	---------------------------------------------------------
	local e0b=Effect.CreateEffect(c)
	e0b:SetType(EFFECT_TYPE_FIELD)
	e0b:SetCode(EFFECT_SPSUMMON_PROC)
	e0b:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0b:SetRange(LOCATION_EXTRA)
	e0b:SetCondition(s.spcon)
	e0b:SetOperation(s.spop)
	c:RegisterEffect(e0b)

	---------------------------------------------------------
	-- ① 특소 성공 시 상대 필드 1장 파괴
	---------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.descon1)
	e1:SetTarget(s.destg1)
	e1:SetOperation(s.desop1)
	c:RegisterEffect(e1)

	---------------------------------------------------------
	-- ② 묘지의 모델 몬스터 장착
	---------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.eqcon)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- 장착 제한
	local e2l=Effect.CreateEffect(c)
	e2l:SetType(EFFECT_TYPE_SINGLE)
	e2l:SetCode(EFFECT_EQUIP_LIMIT)
	e2l:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2l:SetValue(function(e,cc) return e:GetHandler()==cc:GetEquipTarget() end)
	c:RegisterEffect(e2l)

	---------------------------------------------------------
	-- ③ 장착 카드가 1장 이상 → 2회 공격
	---------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetCondition(s.atkcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
end

---------------------------------------------------------
-- 소환 제한
---------------------------------------------------------
function s.splimit(e,se,sp,st)
	if (st & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION then
		return true
	end
	return se:IsHasType(EFFECT_SPSUMMON_PROC)
end

---------------------------------------------------------
-- 고유 특소
---------------------------------------------------------
function s.spfilter(c,code)
	return c:IsCode(code) and c:IsAbleToGraveAsCost()
	   and (c:IsLocation(LOCATION_HAND)
	   or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()))
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,CODE_FITTER)
	   and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,CODE_MODELP)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil,CODE_FITTER)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil,CODE_MODELP)
	g1:Merge(g2)
	Duel.SendtoGrave(g1,REASON_COST)
end

---------------------------------------------------------
-- ① 특소 성공 시
---------------------------------------------------------
function s.descon1(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.desfilter1(c)
	return c:IsDestructable()
end

function s.destg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and chkc:IsControler(1-tp)
		   and s.desfilter1(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.desfilter1,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter1,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop1(e,tp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

---------------------------------------------------------
-- ② 장착
---------------------------------------------------------
function s.eqcon(e)
	return Duel.IsMainPhase()
end

function s.eqfilter(c)
	return c:IsSetCard(0x759) and c:IsMonster()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp)
		   and s.eqfilter(chkc)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		   and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,1,nil)
end

function s.eqop(e,tp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.Equip(tp,tc,c,true) then
			-- Equip Limit
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

---------------------------------------------------------
-- ③ 장착 카드 1장 이상 → 2회 공격
---------------------------------------------------------
function s.atkcon(e)
	return e:GetHandler():GetEquipGroup():GetCount()>0
end
