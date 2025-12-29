--헤블론-빛의 칼바리
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 엑스트라 덱의 "헤블론" 엑시즈 몬스터를 보여주고 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- ②: 이 카드를 소재로 가지고 있는 빛/어둠 속성 엑시즈 몬스터에 효과 부여
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- ① 타겟: 엑스트라 덱의 헤블론 엑시즈 몬스터를 보여주고 이 카드 특수 소환
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

-- ① 필터: 엑스트라 덱의 헤블론 엑시즈 몬스터
function s.exfilter(c)
	return c:IsSetCard(0xc06) and c:IsType(TYPE_XYZ) and not c:IsPublic()
end

-- ① 처리: 엑스트라 덱의 헤블론 엑시즈 몬스터를 보여주고 이 카드 특수 소환
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 엑스트라 덱에서 헤블론 엑시즈 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.exfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g==0 then return end
	
	-- 상대에게 보여주기
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleExtra(tp)
	
	-- 이 카드 특수 소환
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ② 조건: 이 카드를 소재로 가지고 있는 빛/어둠 속성 엑시즈 몬스터
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsType(TYPE_XYZ) 
		and ((c:GetOriginalAttribute()==ATTRIBUTE_LIGHT) or (c:GetOriginalAttribute()==ATTRIBUTE_DARK))
		and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,id)) then
		return false
	end
	
	-- 상대가 패의 몬스터의 효과를 발동했을 때
	local rc=re:GetHandler()
	return Duel.IsChainNegatable(ev) 
		and re:IsActiveType(TYPE_MONSTER)
		and rc:IsLocation(LOCATION_HAND)
		and rp==1-tp
end

-- ② 코스트: 엑시즈 소재 1개 제거
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ② 타겟: 발동 무효
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

-- ② 처리: 발동 무효
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.RaiseEvent(e:GetHandler(),EVENT_NEGATED,e,0,0,0,0)
	end
end
