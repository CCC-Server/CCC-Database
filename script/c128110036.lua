-- 파괴수결전 - 괴수행성
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터
function s.initial_effect(c)
	-- ①: 덱 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: 묘지 소생 + 카운터
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.spcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc82, 0xd3} -- 대괴수결전병기, 파괴수
s.counter_list={COUNTER_KAIJU}

-- ① 효과: 서치 필터
function s.thfilter(c)
	return (c:IsSetCard(0xc82) or c:IsSetCard(0xd3)) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ② 효과: 트리거 필터 (상대에 의해 필드->묘지로 간 파괴수)
function s.cfilter(c,e,tp)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER)
		and c:IsPreviousLocation(LOCATION_ONFIELD) -- 필드에서
		and c:GetReasonPlayer()==1-tp -- 수정됨: 상대에 의해 (전투 또는 효과)
		and c:IsLocation(LOCATION_GRAVE)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 묘지로 보내진 턴에는 발동 불가 (GetTurnID()와 현재 턴 비교)
	return e:GetHandler():GetTurnID()~=Duel.GetTurnCount()
		and eg:IsExists(s.cfilter,1,nil,e,tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 트리거된 카드들 중 소환 가능한 대상 찾기
	local g=eg:Filter(s.cfilter,nil,e,tp)
	if chk==0 then return #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	
	local tc=nil
	if #g==1 then
		tc=g:GetFirst()
	else
		-- 여러 장이 동시에 보내졌다면 선택
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		tc=g:Select(tp,1,1,nil):GetFirst()
	end
	
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,tc,2,0,COUNTER_KAIJU)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
			-- 소환 성공 시 카운터 2개 놓기
			if tc:IsCanAddCounter(COUNTER_KAIJU,2) then
				Duel.BreakEffect()
				tc:AddCounter(COUNTER_KAIJU,2)
			end
		end
	end
end