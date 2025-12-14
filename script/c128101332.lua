--하이메타파이즈 데브리 드래곤
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------------------------------------------------
	-- 튜너 이외의 몬스터로 취급 (메타파이즈 싱크로의 소재로 할 경우)
	--------------------------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_NONTUNER)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetValue(s.ntval)
	c:RegisterEffect(e0)

	--------------------------------------------------------------------------
	--① 일반 / 특수 소환 성공시 : 덱 / 묘지 / 엑스트라 덱(앞면)에서
	--   레벨 4 이하의 "메타파이즈" 몬스터 1장 효과 무효로 특수 소환
	--------------------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sp1tg)
	e1:SetOperation(s.sp1op)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	--------------------------------------------------------------------------
	--② 자신 필드에 "메타파이즈" 싱크로 몬스터가 특수 소환되었을 때,
	--   묘지 / 엑스트라 덱(앞면)의 "메타파이즈" 몬스터 1장을 제외하고
	--   이 카드를 묘지에서 특수 소환, 그 후 레벨을 2 내릴 수 있다.
	--------------------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.sp2con)
	e2:SetCost(s.sp2cost)
	e2:SetTarget(s.sp2tg)
	e2:SetOperation(s.sp2op)
	c:RegisterEffect(e2)

	--------------------------------------------------------------------------
	--③ 이 카드가 제외 상태이고, 카드가 제외되었을 경우:
	--   제외 상태인 "메타파이즈" 몬스터 1장을 자신 필드에 특수 소환
	--------------------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetRange(LOCATION_REMOVED)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.sp3con)
	e3:SetTarget(s.sp3tg)
	e3:SetOperation(s.sp3op)
	c:RegisterEffect(e3)
end

----------------------------------------
-- 비튜너 처리
----------------------------------------
function s.ntval(e,c)
	-- "메타파이즈" 싱크로 몬스터의 소재가 될 경우 비튜너로 취급
	return c and c:IsSetCard(SET_METAPHYS)
end

----------------------------------------
-- ① 효과 : 특수 소환용 필터
----------------------------------------
function s.sp1filter(c,e,tp)
	return c:IsSetCard(SET_METAPHYS) and c:IsLevelBelow(4)
		and (not c:IsLocation(LOCATION_EXTRA) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sp1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.sp1filter),
				tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA)
end
function s.sp1op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,
		aux.NecroValleyFilter(s.sp1filter),
		tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 효과 무효
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

----------------------------------------
-- ② 효과 : 자신 필드에 메타파이즈 싱크로 특소 감지
----------------------------------------
function s.sp2cfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp)
		and c:IsSetCard(SET_METAPHYS) and c:IsType(TYPE_SYNCHRO)
end
function s.sp2con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.sp2cfilter,1,nil,tp)
end

-- 코스트로 제외할 "메타파이즈" 몬스터
function s.sp2costfilter(c)
	return c:IsSetCard(SET_METAPHYS) and c:IsMonster()
		and (not c:IsLocation(LOCATION_EXTRA) or c:IsFaceup())
		and c:IsAbleToRemoveAsCost()
end
function s.sp2cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.sp2costfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.sp2costfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.sp2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.sp2op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 and c:IsFaceup() then
		-- 레벨을 2 내릴지 선택
		if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_LEVEL)
			e1:SetValue(-2)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end

----------------------------------------
-- ③ 효과 : 제외 트리거 / 대상 & 발동
----------------------------------------
function s.sp3con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 이 카드가 이미 제외 상태일 때, 다른 카드가 제외된 경우만 발동
	return c:IsFaceup() and not eg:IsContains(c)
end
function s.sp3filter(c,e,tp)
	return c:IsSetCard(SET_METAPHYS) and c:IsFaceup()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sp3tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp)
			and s.sp3filter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.sp3filter,tp,LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.sp3filter,tp,LOCATION_REMOVED,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.sp3op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
