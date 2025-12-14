--카드명 : 어메이즈먼트 마스코트 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 특수 소환 + 추가 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

--② 어트랙션 재장착 / 교체
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,1))
e3:SetCategory(CATEGORY_EQUIP+CATEGORY_TOGRAVE)
e3:SetType(EFFECT_TYPE_QUICK_O)
e3:SetCode(EVENT_FREE_CHAIN)
e3:SetRange(LOCATION_MZONE)
e3:SetCountLimit(1,{id,1})
e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
e3:SetCondition(s.eqcon)
e3:SetTarget(s.eqtg)
e3:SetOperation(s.eqop)
c:RegisterEffect(e3)

end
s.listed_series={0x15e,0x15f}

--① 덱에서 어메이즈먼트 특수 소환 + 추가 일반 소환 부여
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x15e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp):GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		--추가 일반 소환
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
		e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
		e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x15e))
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
	--링크 몬스터만 엑스트라 특소 제한
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetTargetRange(1,0)
	e2:SetTarget(function(_,c) return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_LINK) end)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

--② 어트랙션 조정
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x15e),tp,LOCATION_MZONE,0,1,nil)
end
function s.eqfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x15f) and c:GetEquipTarget()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return s.eqfilter(chkc) and chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_SZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_SZONE,0,1,1,nil)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	local choice=0
	--0=장착 몬스터 변경, 1=묘지로 보내기
	if Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,tc:GetEquipTarget()) then
		choice=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	else
		choice=1
	end
	if choice==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
		local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,tc:GetEquipTarget())
		local ec=g:GetFirst()
		if ec then
			Duel.Equip(tp,tc,ec,true)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(function(e,c) return c==ec end)
			tc:RegisterEffect(e1)
		end
	elseif choice==1 then
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end

	-- ✅ 공통 처리: 덱에서 어트랙션 선택 후 상대 몬스터에 장착
	if Duel.IsExistingMatchingCard(s.deckeqfilter,tp,LOCATION_DECK,0,1,nil,e,tp) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
		local g=Duel.SelectMatchingCard(tp,s.deckeqfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		local sc=g:GetFirst()
		if sc then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			local ec=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
			if ec then
				Duel.Equip(tp,sc,ec,true)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_EQUIP_LIMIT)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				e1:SetValue(function(e,c) return c==ec end)
				sc:RegisterEffect(e1)
			end
		end
	end
end

function s.deckeqfilter(c,e,tp)
	return c:IsSetCard(0x15f) and c:IsType(TYPE_TRAP) and not c:IsForbidden()
end


