-- 데드웨어 데이터 인크립터
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환 소재: 레벨 3 "데드웨어" 몬스터 × 2
	Xyz.AddProcedure(c,s.xyzfilter,3,2)
	c:EnableReviveLimit()
	
	-- ①: 자신 / 상대 턴에 묘지 소생 + 조건부 레벨 변경 (1턴에 1번)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	
	-- ②: 상대가 드로우 페이즈 이외에 카드를 패에 넣었을 경우 발동 (1턴에 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_HANDES+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.hdcon2)
	e2:SetTarget(s.hdtg2)
	e2:SetOperation(s.hdop2)
	c:RegisterEffect(e2)
	
	-- 전역 체크: 이 턴에 자신의 카드가 상대 패로 들어갔는지 감시
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TO_HAND)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

-- 엑시즈 소재 필터
function s.xyzfilter(c,xyz,sumtype,tp)
	return c:IsSetCard(0xc55,xyz,sumtype,tp) and c:IsXyzLevel(xyz,3)
end

-- 카드 이동 감지 (자신의 카드가 상대의 패에 넣어졌을 경우 플래그)
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	while tc do
		-- 원래 주인이 tp인데 컨트롤러가 1-tp인 상태로 패에 들어갔을 경우
		if tc:IsLocation(LOCATION_HAND) and tc:GetOwner()==tp and tc:GetControler()==1-tp then
			Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		-- 반대 경우(상대 카드 추적)도 필요하다면 아래 추가
		elseif tc:IsLocation(LOCATION_HAND) and tc:GetOwner()==1-tp and tc:GetControler()==tp then
			Duel.RegisterFlagEffect(1-tp,id,RESET_PHASE+PHASE_END,0,1)
		end
		tc=eg:GetNext()
	end
end

-- ① 효과 로직
function s.spcost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc55) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 이번 턴에 자신의 카드가 상대 패로 넣어졌을 경우(Flag 확인) 레벨 7로 변경 선택
		if Duel.GetFlagEffect(tp,id)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL)
			e1:SetValue(7)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end

-- ② 효과 로직
function s.hfilter(c,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND)
end
function s.hdcon2(e,tp,eg,ep,ev,re,r,rp)
	-- 상대(1-tp)의 패에 카드가 들어왔고 드로우 페이즈가 아님
	return not Duel.IsPhase(PHASE_DRAW) and eg:IsExists(s.hfilter,1,nil,1-tp)
end
function s.hdtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- 이벤트에서 발생한 카드들을 타겟으로 설정
	local g=eg:Filter(s.hfilter,nil,1-tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,1-tp,1)
end
function s.hdop2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e):Filter(Card.IsLocation,nil,LOCATION_HAND)
	if #g==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_DISCARD)
	local sg=g:Select(1-tp,1,1,nil)
	local dc=sg:GetFirst()
	if dc and Duel.SendtoGrave(dc,REASON_EFFECT+REASON_DISCARD)>0 then
		-- 버려진 카드가 "데드웨어" 카드일 경우 추가 효과
		if dc:IsSetCard(0xc55) then
			local mg=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_GRAVE,nil)
			if #mg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local tg=mg:Select(tp,1,1,nil)
				if #tg>0 then
					Duel.SendtoHand(tg,tp,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,tg)
				end
			end
		end
	end
end