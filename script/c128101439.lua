--종이 비행기 라이벌 - 쟈이츠
local s,id=GetID()
function s.initial_effect(c)
	-- "Paper Plane" 카드군
	s.listed_series={0xc53}

	--------------------------------
	-- ① 패에서 퀵 효과:
	--   장착 마법 1장 파괴 → 이 카드를 패에서 특수 소환
	--   (이 카드명의 ① 효과는 1턴에 1번)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 퀵: 상대 몬스터 1장을 이 카드에 장착 마법으로 장착
	--      그 후, 이 카드의 ATK는 그 몬스터의 ATK만큼 상승
	--   (이 카드명의 ② 효과는 1턴에 1번)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.eqtg2)
	e2:SetOperation(s.eqop2)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- ① 장착 마법 파괴 → 패에서 특수 소환
--------------------------------------------------
function s.desfilter(c)
	-- 필드 위의 앞면 장착 마법 카드
	return c:IsFaceup() and c:IsType(TYPE_EQUIP) and c:IsType(TYPE_SPELL)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and s.desfilter(chkc)
	end
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingTarget(s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.Destroy(tc,REASON_EFFECT)==0 then return end
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

--------------------------------------------------
-- ② 상대 몬스터 1장을 이 카드에 장착 마법으로 장착
--    그 후, 이 카드의 ATK는 그 몬스터의 ATK만큼 상승
--------------------------------------------------
function s.eqfilter2(c)
	-- 상대 필드의 앞면 몬스터 (토큰 제외)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and not c:IsType(TYPE_TOKEN)
end
function s.eqtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and chkc:IsControler(1-tp) and s.eqfilter2(chkc)
	end
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and c:IsFaceup()
			and Duel.IsExistingTarget(s.eqfilter2,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter2,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end

function s.eqlimit2(e,c)
	-- 이 장착 카드는 지정된 몬스터(쟈이츠)에만 장착 가능
	return c==e:GetLabelObject()
end

function s.eqop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if not tc:IsControler(1-tp) or not tc:IsLocation(LOCATION_MZONE) then return end
	if tc:IsType(TYPE_TOKEN) then return end

	-- 원래 공격력 기록
	local orig_atk=tc:GetTextAttack()
	if orig_atk<0 then orig_atk=0 end

	-- 상대 몬스터 tc를 이 카드에 장착
	if not Duel.Equip(tp,tc,c,true) then return end

	-- 장착된 카드를 "장착 마법 카드"로 취급 (SPELL + EQUIP)
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
	e1:SetValue(s.eqlimit2)
	e1:SetLabelObject(c)
	tc:RegisterEffect(e1)

	-- 이 카드의 ATK는 그 몬스터의 ATK만큼 상승
	if orig_atk>0 then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_EQUIP)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(orig_atk)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end
