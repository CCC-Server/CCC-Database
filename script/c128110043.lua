-- H·C(히로익 챌린저) 리벤지 폴암
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 자신 / 상대 턴 패 특수 소환 + LP 500
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMING_MAIN_END+TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	
	-- ②: 소환시 상대가 고르고 덱으로 되돌리기 (명령 효과)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function(e,tp) return Duel.IsTurnPlayer(tp) end)
	e2:SetTarget(s.tdtg2)
	e2:SetOperation(s.tdop2)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
	
	-- ③: 서로의 메인 페이즈 서치 + 효과 데미지 0
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetHintTiming(0,TIMING_MAIN_END)
	e3:SetCondition(s.thcon3)
	e3:SetTarget(s.thtg3)
	e3:SetOperation(s.thop3)
	c:RegisterEffect(e3)
end

s.listed_series={0x106f} -- 히로익
s.listed_names={id}

-- ① 조건: 상대 필드에만 몬스터 존재
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
		and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- LP를 500으로 변경
	Duel.SetLP(tp,500)
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- "다음 턴 종료시까지" 히로익 특수 소환 제약
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetDescription(aux.Stringid(id,3))
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit1)
		e1:SetReset(RESET_PHASE+PHASE_END,2) -- 이번 턴 + 다음 턴
		Duel.RegisterEffect(e1,tp)
	end
end
function s.splimit1(e,c)
	return not c:IsSetCard(0x6f)
end

-- ② 체인 불가(몬스터 효과) 및 덱으로 되돌리기
function s.tdtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	-- LP 차이가 7000 이상이면 상대는 몬스터 효과를 체인 불가
	if Duel.GetLP(tp)<=Duel.GetLP(1-tp)-7000 then
		Duel.SetChainLimit(s.chlimit)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,1-tp,LOCATION_MZONE)
end
function s.chlimit(e,rp,tp)
	return not e:IsActiveType(TYPE_MONSTER)
end
function s.tdfilter2(c)
	return c:IsFaceup() and c:GetAttack()>0 and c:IsAbleToDeck()
end
function s.tdop2(e,tp,eg,ep,ev,re,r,rp)
	local lp=Duel.GetLP(tp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local sum=g:GetSum(Card.GetAttack)
	-- 상대 몬스터 공격력 합계가 내 LP 이하라면 처리 안함
	if sum<=lp then return end
	
	-- 상대가 고르고 덱으로 되돌림 (REASON_RULE: 완전 내성 몬스터도 제거 가능)
	while sum>lp do
		local tg=Duel.GetMatchingGroup(s.tdfilter2,tp,0,LOCATION_MZONE,nil)
		if #tg==0 then break end
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TODECK)
		local sg=tg:Select(1-tp,1,1,nil)
		if #sg==0 then break end
		Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_RULE)
		
		-- 다시 합계 계산
		local next_g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		sum=next_g:GetSum(Card.GetAttack)
	end
end

-- ③ 메인 페이즈 서치
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.thfilter3(c)
	return c:IsSetCard(0x6f) and c:IsAbleToHand()
end
function s.thtg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter3,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop3(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter3,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		-- 발동 시 LP 500 이하였다면 효과 데미지 차단
		if Duel.GetLP(tp)<=500 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CHANGE_DAMAGE)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetTargetRange(1,0)
			e1:SetValue(0)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e2,tp)
		end
	end
end