-- 엘, 모델의 적합자 + 모델O
local s,id=GetID()
local CODE_FITTER = 128770189 -- 엘, 모델의 적합자
local CODE_MODELO = 128770196 -- 모델O

function s.initial_effect(c)
	---------------------------------------------------------
	-- 융합 소환
	---------------------------------------------------------
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CODE_FITTER,CODE_MODELO)

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
	-- 고유 특수 소환 (패/필드 → 묘지)
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
	-- ① 특소 성공 시: 적합자 패로 OR 특수 소환
	---------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.thspcon)
	e1:SetTarget(s.thsptg)
	e1:SetOperation(s.thspop)
	c:RegisterEffect(e1)

	---------------------------------------------------------
	-- ② 묘지의 '모델' 몬스터 장착
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
	-- ③ 장착 카드 1장 이상 → 전투/효과 파괴 내성
	---------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetCondition(s.indcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	local e3b=e3:Clone()
	e3b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e3b)
end

---------------------------------------------------------
-- 특소 제한
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
	return c:IsCode(code)
		and c:IsAbleToGraveAsCost()
		and (c:IsLocation(LOCATION_HAND)
		or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()))
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,CODE_FITTER)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,CODE_MODELO)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil,CODE_FITTER)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil,CODE_MODELO)
	g1:Merge(g2)
	Duel.SendtoGrave(g1,REASON_COST)
end

---------------------------------------------------------
-- ① 적합자 회수 / 특소
---------------------------------------------------------
function s.thspcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.thspfilter(c,e,tp)
	return c:IsCode(CODE_FITTER)
		and (c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end

function s.thsptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.IsExistingTarget(s.thspfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
	Duel.SelectTarget(tp,s.thspfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
end

function s.thspop(e,tp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local b1=tc:IsAbleToHand()
	local b2=tc:IsCanBeSpecialSummoned(e,0,tp,false,false)

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then
		op=0
	else
		op=1
	end

	if op==0 then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	else
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

---------------------------------------------------------
-- ② 장착
---------------------------------------------------------
function s.eqcon(e)
	return Duel.IsMainPhase()
end

function s.eqtargetfilter(c)
	return c:IsSetCard(0x759) and c:IsMonster()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp)
			and s.eqtargetfilter(chkc)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(s.eqtargetfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqtargetfilter,tp,LOCATION_GRAVE,0,1,1,nil)
end

function s.eqop(e,tp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
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

---------------------------------------------------------
-- ③ 장착 카드 있음 → 파괴 내성
---------------------------------------------------------
function s.indcon(e)
	return e:GetHandler():GetEquipGroup():GetCount()>0
end

