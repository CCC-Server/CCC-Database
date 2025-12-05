--종이 비행기 소도이츠
--Paper Plane Sodoitsu
local s,id=GetID()
function s.initial_effect(c)
	-- 기본 정보
	c:EnableReviveLimit()
	-- 융합 소재: "Paper Plane - Soitsu"(128101437) + 1장 "Paper Plane" 몬스터
	-- 직접 필터 함수를 정의해서 AddProcMix에 넣어, CheckFusionMaterial에서 타입 꼬임 방지
	Fusion.AddProcMix(c,true,true,s.fusmat1,s.fusmat2)
	
	s.listed_series={0xc53}
	s.listed_names={128101437}

	--------------------------------
	-- ① 융합 소환 성공시, 덱에서 "Paper Plane" 카드 1장 묘지로
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.tgcon1)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.tgtg1)
	e1:SetOperation(s.tgop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 퀵: 묘지의 유니온 몬스터 1장을 이 카드에 장착 마법으로 장착
	--      그 후, 상대 필드의 몬스터 1장의 효과를 턴 종료시까지 무효
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
end

--------------------------------
-- 융합 소재 필터
-- 이 형태 (c,fc,sumtype,tp)를 받는 함수면 CheckFusionMaterial에서 안전하게 사용 가능
--------------------------------
-- "Paper Plane - Soitsu" 1장
function s.fusmat1(c,fc,sumtype,tp)
	return c:IsCode(128101437)
end
-- "Paper Plane" 몬스터 1장
function s.fusmat2(c,fc,sumtype,tp)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER)
end

--------------------------------
-- ① 융합 소환 성공시 덱에서 "Paper Plane" 카드 1장 묘지로
--------------------------------
function s.tgcon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.tgfilter1(c)
	return c:IsSetCard(0xc53) and c:IsAbleToGrave()
end
function s.tgtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tgfilter1,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

--------------------------------
-- ② 유니온 장착 + 상대 몬스터 효과 무효
--------------------------------
function s.eqfilter(c)
	-- 묘지의 유니온 몬스터
	return c:IsType(TYPE_MONSTER) and c:IsType(TYPE_UNION)
		and not c:IsForbidden()
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
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end

function s.eqlimit(e,c)
	-- 이 장착 카드는 지정된 몬스터(소도이츠)에만 장착 가능
	return c==e:GetLabelObject()
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and c:IsFaceup()) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end

	-- 묘지의 유니온 몬스터를 이 카드에 장착
	if not Duel.Equip(tp,tc,c,true) then return end

	-- 타입을 "장착 마법 카드"로 취급 (SPELL + EQUIP)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_TYPE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
	e0:SetValue(TYPE_SPELL+TYPE_EQUIP)
	tc:RegisterEffect(e0)

	-- 장착 제한 (이 몬스터에만)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(s.eqlimit)
	e1:SetLabelObject(c)
	tc:RegisterEffect(e1)

	-- 그 후, 상대 필드의 몬스터 1장의 효과를 턴 종료시까지 무효
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local sg=g:Select(tp,1,1,nil)
		local mc=sg:GetFirst()
		if mc and mc:IsFaceup() and not mc:IsImmuneToEffect(e) then
			Duel.NegateRelatedChain(mc,RESET_TURN_SET)
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			mc:RegisterEffect(e2)
			local e3=e2:Clone()
			e3:SetCode(EFFECT_DISABLE_EFFECT)
			mc:RegisterEffect(e3)
		end
	end
end
