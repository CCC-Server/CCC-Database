local s,id=GetID()
function s.initial_effect(c)
	-- 커스텀 싱크로 소환 조건
	Synchro.AddProcedure(c,s.tunerfilter,1,1,s.nontunerfilter,1,99)
	c:EnableReviveLimit()

	-- ① 상대가 패/필드 몬스터 효과 발동 시 → 파괴 + 1000 데미지
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)

	-- ② 상대에 의해 파괴 시 → 화염/수비력200/비싱크로 몬스터 최대 3장 특소
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- 🔹싱크로 소재 조건
function s.tunerfilter(c,sc,sumtype,tp)
	return c:IsType(TYPE_TUNER) and c:IsSetCard(0x39)
end
function s.nontunerfilter(c,sc,sumtype,tp)
	return not c:IsType(TYPE_TUNER) and c:IsSetCard(0x39)
end

---------------------------------------------------
-- ① 효과: 상대가 패/필드의 몬스터 효과 발동 시
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
		and (rc:IsLocation(LOCATION_HAND) or rc:IsLocation(LOCATION_MZONE))
		and rc:IsControler(1-tp)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) and Duel.Destroy(rc,REASON_EFFECT)>0 then
		Duel.Damage(1-tp,1000,REASON_EFFECT)
	end
end

---------------------------------------------------
-- ② 조건: 싱크로 소환된 이 카드가 상대에 의해 파괴됨
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_SYNCHRO)
		and r&REASON_DESTROY~=0
		and rp==1-tp
end

-- 🔹묘지에서 특소 대상 필터: 비싱크로 / 수비력 200 / 화염속성
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:GetDefense()==200
		and not c:IsType(TYPE_SYNCHRO)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=math.min(3,Duel.GetLocationCount(tp,LOCATION_MZONE))
	if chk==0 then return ft>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,ft,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=math.min(3,Duel.GetLocationCount(tp,LOCATION_MZONE))
	if ft<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,ft,nil,e,tp)
	if #g==0 then return end
	for tc in aux.Next(g) do
		if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE) then
			-- 효과 무효화
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
	Duel.SpecialSummonComplete()
end
