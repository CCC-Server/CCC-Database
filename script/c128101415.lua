--Horuz LV8 (가칭)
local s,id=GetID()
local SET_HORUS=0x1003  -- "호루스의 흑염룡" 카드군 코드

function s.initial_effect(c)
	--------------------------------------
	-- (1) 패에서 특소 + 마법 발동 무효 & 세트
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCountLimit(1,id) -- (1)(2) 공유 HOPT
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--------------------------------------
	-- (2) 퀵 : 호루스 카드 1장 묘지로 → 카드 1장 묘지 보내기
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,id) -- (1)(2) 공유 HOPT
	e2:SetCost(s.tgcost2)
	e2:SetTarget(s.tgtg2)
	e2:SetOperation(s.tgop2)
	c:RegisterEffect(e2)

	--------------------------------------
	-- (3) 다른 "호루스" 몬스터 대상 내성 (상대의 마/함 효과)
	--------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.protg)
	e3:SetValue(s.protval)
	c:RegisterEffect(e3)
end

--------------------------------------------------
-- (1) 상대 마법 카드 발동에 체인해서 패에서 특소 + 무효 & 세트
--------------------------------------------------
function s.lv6horusfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_HORUS) and c:IsMonster() and c:IsLevelAbove(6)
end
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_SPELL)
		and re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.lv6horusfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	-- 특수 소환에 성공하면
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 발동 무효
		if Duel.NegateActivation(ev) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and rc:IsRelateToEffect(re) and rc:IsType(TYPE_SPELL) then
			Duel.BreakEffect()
			-- 무효가 된 마법 카드를 자신의 마/함 존에 세트
			Duel.MoveToField(rc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
		end
	end
end

--------------------------------------------------
-- (2) 코스트 : 자신 필드의 "호루스의 흑염룡" 카드 1장 묘지
--------------------------------------------------
function s.tgcostfilter(c,tp)
	return c:IsSetCard(SET_HORUS) and c:IsAbleToGraveAsCost()
		and c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD)
end
function s.tgcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tgcostfilter,tp,LOCATION_ONFIELD,0,1,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgcostfilter,tp,LOCATION_ONFIELD,0,1,1,nil,tp)
	Duel.SendtoGrave(g,REASON_COST)
end

--------------------------------------------------
-- (2) 대상 지정 & 처리 : 카드 1장 묘지 보내기
--------------------------------------------------
function s.tgtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end
function s.tgop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end
end

--------------------------------------------------
-- (3) 보호 효과 : 다른 "호루스" 몬스터 대상 내성
--------------------------------------------------
function s.protg(e,c)
	local tp=e:GetHandlerPlayer()
	return c:IsControler(tp) and c:IsSetCard(SET_HORUS) and c:IsMonster()
		and c~=e:GetHandler()
end
function s.protval(e,re,rp)
	return rp==1-e:GetHandlerPlayer() and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end
