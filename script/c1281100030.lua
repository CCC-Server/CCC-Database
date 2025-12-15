-- 대괴수결전병기 - 99식 메이서 살룡전차
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 패/묘지 제외하고 발동 (지속물 놓기 or 서치)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetCost(aux.bfgcost)
	e1:SetTarget(s.tftg)
	e1:SetOperation(s.tfop)
	c:RegisterEffect(e1)

	-- ②: 상대 파괴수 무효 후 특소 + 엑트 제약
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_REMOVED)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	
	-- 엑스트라 덱 소환 횟수 카운팅 (②번 효과용)
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end

	-- ③: 특소 성공 시 융합 (소재 덱으로)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.fsptg)
	e3:SetOperation(s.fspop)
	c:RegisterEffect(e3)
end
s.listed_series={0xd3, 0xc72} -- 파괴수, 대괴수결전병기

-- ① 효과: 지속물 필터 (파괴수 지속 마/함)
function s.tffilter(c,tp)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS) and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end
-- ① 효과: 서치 필터 (파괴수 마/함)
function s.thfilter(c)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
-- ① 효과: 파괴수 몬스터 체크용
function s.kaijufilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER)
end

function s.tftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.IsExistingMatchingCard(s.tffilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp)
	local b2=Duel.IsExistingMatchingCard(s.kaijufilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) 
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	if chk==0 then return b1 or b2 end
end

function s.tfop(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.IsExistingMatchingCard(s.tffilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp)
	local b2=Duel.IsExistingMatchingCard(s.kaijufilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) 
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end

	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.tffilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tp):GetFirst()
		if tc then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

-- ② 효과: 엑스트라 덱 소환 횟수 체크
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	for tc in aux.Next(eg) do
		if tc:IsSummonLocation(LOCATION_EXTRA) then
			Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.kaijufilter,tp,0,LOCATION_MZONE,1,nil)
end

function s.disfilter(c)
	return s.kaijufilter(c) and not c:IsDisabled() and (c:IsType(TYPE_EFFECT) or c:GetOriginalType()&TYPE_EFFECT~=0)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and s.disfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingTarget(s.disfilter,tp,0,LOCATION_MZONE,1,nil)
		and Duel.GetFlagEffect(tp,id) < 2 -- "1장밖에" 제한 고려 (이미 2장 이상이면 발동 불가)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.disfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
		
		if c:IsRelateToEffect(e) then
			Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		end
	end
	
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e3:SetTargetRange(1,0)
	e3:SetTarget(s.splimit)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and Duel.GetFlagEffect(e:GetHandlerPlayer(),id)>=1
end

-- ③ 효과: 융합 소재 필터 (이번 턴에 특수 소환된 몬스터만)
function s.matfilter(c,e)
	-- [수정됨] STATUS_SUMMON_TURN 대신 TurnID 확인을 사용하여 더 확실하게 판별
	-- 필드 융합이므로 IsFaceup() 추가 권장
	return c:IsAbleToDeck() and c:IsSummonType(SUMMON_TYPE_SPECIAL) 
		and c:IsFaceup() 
		and c:GetTurnID()==Duel.GetTurnCount() 
		and not c:IsImmuneToEffect(e)
end

-- ③ 효과: 융합 몬스터 필터
function s.ffilter(c,e,tp,m,chkf)
    return c:IsType(TYPE_FUSION) and c:CheckFusionMaterial(m,nil,chkf)
        and c.counter_place_list
end
function s.fsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,e)
		return #mg>0 and Duel.IsExistingMatchingCard(s.ffilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_ONFIELD)
end

function s.fspop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,e)
	if #mg==0 then return end

	local sg1=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,chkf)
	if #sg1==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=sg1:Select(tp,1,1,nil):GetFirst()
	if not tc then return end

	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
	if not mat or #mat==0 then return end

	-- 소재가 덱으로 돌아간 뒤 엑스트라 덱 몬스터가 나올 공간이 있는지 확인
	local matc=mat:Filter(Card.IsControler,nil,tp)
	if Duel.GetLocationCountFromEx(tp,tp,matc,tc)<=0 then
		Duel.Hint(HINT_MSG,tp,STRING_INVALID_SELECTION) -- 공간 부족 메시지
		return 
	end

	tc:SetMaterial(mat)
	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end