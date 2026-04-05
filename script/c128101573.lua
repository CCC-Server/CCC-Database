-- 스타토치 아카데미 린네
local s,id=GetID()
function s.initial_effect(c)
	-- "스타토치 아카데미" 세트코드 지정
	local SETCODE_STARTORCH = 0xc57

	-- ①: 자신 필드의 "스타토치 아카데미" 카드 1장을 대상으로 하고 발동 (패 특소)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg(SETCODE_STARTORCH))
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 일반 소환/특수 소환/효과 파괴 시 발동 (마함 세트 및 의식 릴리스 대체)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg(SETCODE_STARTORCH))
	e2:SetOperation(s.setop(SETCODE_STARTORCH))
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	-- 효과로 파괴되어 묘지/제외/엑스트라 덱(앞면)으로 갔을 때의 트리거
	local e4=e2:Clone()
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCondition(s.descon)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e5)
	local e6=e4:Clone()
	e6:SetCode(EVENT_TO_DECK) -- EVENT_TO_EXTRA 대신 EVENT_TO_DECK 사용
	c:RegisterEffect(e6)

	-- ③: 자신/상대 턴에 발동 (자신 파괴 후 묘지/엑덱 특소)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_FREE_CHAIN)
	e7:SetRange(LOCATION_MZONE)
	e7:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e7:SetCountLimit(1,{id,2})
	e7:SetTarget(s.sp2tg(SETCODE_STARTORCH))
	e7:SetOperation(s.sp2op(SETCODE_STARTORCH))
	c:RegisterEffect(e7)
end

-- [효과 ① 함수]
function s.desfilter(c,setcode)
	return c:IsFaceup() and c:IsSetCard(setcode)
end
function s.sptg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(tp) and s.desfilter(chkc,setcode) end
		if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,LOCATION_ONFIELD,0,1,nil,setcode)
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil,setcode)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 and c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- [효과 ② 함수]
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 효과로 파괴된 경우인지 확인
	return c:IsReason(REASON_EFFECT) and c:IsReason(REASON_DESTROY)
end
function s.setfilter(c,setcode)
	return c:IsSetCard(setcode) and c:IsSpellTrap() and c:IsSSetable()
end
function s.settg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil,setcode) end
	end
end
function s.setop(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil,setcode)
		if #g>0 then
			Duel.SSet(tp,g)
			local tc=g:GetFirst()
			-- 의식 마법을 세트했을 경우, 이 카드를 1장으로 의식 릴리스 충당 가능하도록 설정
			if tc:IsRitualSpell() then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_RITUAL_LEVEL)
				e1:SetValue(s.ritlevel)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				c:RegisterEffect(e1)
			end
		end
	end
end
function s.ritlevel(e,rc)
	return 255
end

-- [효과 ③ 함수]
function s.sp2filter(c,e,tp,setcode)
	return c:IsSetCard(setcode) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and ((c:IsLocation(LOCATION_GRAVE)) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
end
function s.sp2tg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		local c=e:GetHandler()
		if chk==0 then return c:IsDestructable()
			and Duel.GetMZoneCount(tp,c)>0
			and Duel.IsExistingMatchingCard(s.sp2filter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil,e,tp,setcode) end
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,c,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_EXTRA)
	end
end
function s.sp2op(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if c:IsRelateToEffect(e) and Duel.Destroy(c,REASON_EFFECT)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.sp2filter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil,e,tp,setcode)
			if #g>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end