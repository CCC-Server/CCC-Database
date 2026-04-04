-- H·C(히로익 챌린저) 클러스터 자벨린
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 히로익 몬스터의 효과 발동을 위해 버려졌을 경우 특수 소환 + 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	
	-- ②: 이 카드를 소재로 하는 "히로익" 엑시즈 몬스터에게 효과 부여
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.efcon)
	e2:SetOperation(s.efop)
	c:RegisterEffect(e2)
	
	-- ③: 묘지에서 발동하는 엑시즈 소환 효과
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.xyzcon3)
	e3:SetTarget(s.xyztg3)
	e3:SetOperation(s.xyzop3)
	c:RegisterEffect(e3)
end

s.listed_series={0x6f} -- 히로익
s.listed_names={id}

-- ① 조건: 히로익(0x6f) 몬스터의 효과 코스트로 패에서 버려졌을 때
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DISCARD) and c:IsReason(REASON_COST)
		and re and re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSetCard(0x6f)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thfilter1(c)
	return c:IsSetCard(0x6f) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
	-- 특수 소환 제약: 히로익(0x6f)만 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.splimit1(e,c)
	return not c:IsSetCard(0x6f)
end

-- ② 효과 부여 조건: 히로익(0x6f) 엑시즈 몬스터의 소재가 되었을 때
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_XYZ and e:GetHandler():GetReasonCard():IsSetCard(0x6f)
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	
	-- ● 자신 / 상대 턴 묘지의 히로익 2장 소재로 하기 (퀵 효과)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.mttg)
	e1:SetOperation(s.mtop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e1,true)
	
	-- ● LP 500 이하일 때 "히로익" 카드용 LP 코스트 면제
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_LPCOST_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ALL,0)
	e2:SetCondition(s.lpcon)
	e2:SetTarget(s.lptg)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e2,true)
	
	if not rc:IsType(TYPE_EFFECT) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_ADD_TYPE)
		e3:SetValue(TYPE_EFFECT)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e3,true)
	end
end

-- 부여 효과 A: 소재 충전 (묘지의 히로익 몬스터 2장)
function s.mtfilter(c)
	return c:IsSetCard(0x6f) and c:IsType(TYPE_MONSTER)
end
function s.mttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.mtfilter,tp,LOCATION_GRAVE,0,2,nil) end
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.mtfilter,tp,LOCATION_GRAVE,0,2,2,nil)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end

-- 부여 효과 B: LP 지불 면제 판정
function s.lpcon(e)
	return Duel.GetLP(e:GetHandlerPlayer())<=500
end
function s.lptg(e,re,tp,chk)
	if chk==0 then return re:GetHandler():IsSetCard(0x6f) end
	return true
end

-- ③ 묘지 발동: 엑스트라 덱에서 "H-C"(히로익 엑시즈) 특수 소환
function s.xyzcon3(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp)<=500
end
-- "No."(0x48) 이외의 "히로익"(0x6f) 엑시즈 필터
function s.xyzfilter3(c,e,tp)
	return c:IsSetCard(0x6f) and c:IsType(TYPE_XYZ) and not c:IsSetCard(0x48)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.xyztg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_XYZ)>0
		and Duel.IsExistingMatchingCard(s.xyzfilter3,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.xyzop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_XYZ)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter3,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
		if c:IsRelateToEffect(e) then
			-- 자신을 소재로 함
			Duel.Overlay(tc,Group.FromCards(c))
		end
	end
end