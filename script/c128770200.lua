-- 엘, 모델의 적합자 + 모델Z
local s,id=GetID()
local CODE_FITTER = 128770189 -- 엘, 모델의 적합자
local CODE_MODELZ = 128770191 -- 모델Z

function s.initial_effect(c)
	---------------------------------------------------------
	-- 융합 몬스터 기본 설정
	---------------------------------------------------------
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CODE_FITTER,CODE_MODELZ)

	---------------------------------------------------------
	-- 소환 제한 : 융합 소환 또는 고유 특소만 가능
	---------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	---------------------------------------------------------
	-- 고유 특소 절차 (패/필드 소재 묘지)
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
	-- ① 특소 성공 시: 덱에서 ‘모델’ S/T 1장 세트
	---------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	---------------------------------------------------------
	-- ② 묘지의 모델 몬스터 장착 (메인 페이즈, Quick)
	---------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.eqcon)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	---------------------------------------------------------
	-- ③ 상대 필드의 S/T 파괴
	---------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,3})
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

---------------------------------------------------------
-- 소환 제한
---------------------------------------------------------
function s.splimit(e,se,sp,st)
	-- 융합 소환은 항상 허용
	if (st & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION then
		return true
	end
	-- 고유 특소는 프로시저 효과로만 허용
	return se:IsHasType(EFFECT_SPSUMMON_PROC)
end

---------------------------------------------------------
-- 고유 특소 절차
---------------------------------------------------------
function s.spfilter(c,code)
	return c:IsCode(code)
		and c:IsAbleToGraveAsCost()
		and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()))
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,CODE_FITTER)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,CODE_MODELZ)
end

function s.spop(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil,CODE_FITTER)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil,CODE_MODELZ)
	g1:Merge(g2)
	Duel.SendtoGrave(g1,REASON_COST)
end

---------------------------------------------------------
-- ① 특소 성공 시 S/T 세트
---------------------------------------------------------
function s.setcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.setfilter(c)
	return c:IsSetCard(0x759) and c:IsSpellTrap() and c:IsSSetable()
end

function s.settg(e,tp)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

function s.setop(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
		Duel.ConfirmCards(1-tp,g)
	end
end

---------------------------------------------------------
-- ② 장착
---------------------------------------------------------
function s.eqcon(e,tp)
	return Duel.IsMainPhase()
end

function s.eqfilter(c)
	return c:IsSetCard(0x759) and c:IsMonster()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.eqfilter(chkc) end
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
		if Duel.Equip(tp,tc,c) then
			-- Equip Limit 부여 (정석)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(function(e,ec) return ec==c end)
			tc:RegisterEffect(e1)
		end
	end
end

---------------------------------------------------------
-- ③ S/T 파괴
---------------------------------------------------------
function s.desfilter(c)
	return c:IsSpellTrap() and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and s.desfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
end

function s.desop(e,tp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
