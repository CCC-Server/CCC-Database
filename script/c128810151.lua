--헤블론-루크의 권능
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 몬스터의 효과 / 마법 / 함정 카드가 발동했을 때에 발동할 수 있다. 자신 필드의 "헤블론" 엑시즈 몬스터의 엑시즈 소재를 1개 제거하고, 그 발동을 무효로 하여 파괴한다.
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- ②: 이 카드가 묘지에 존재하는 상태에서, 빛 / 어둠 속성 엑시즈 몬스터가 엑시즈 소환되었을 경우에 발동할 수 있다. 이 카드를 자신 필드에 세트한다. 이 효과로 세트한 이 카드는 필드에서 벗어났을 경우에 제외된다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOFIELD)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.recccon)
	e2:SetTarget(s.reccttg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 발동 조건: 몬스터 효과 / 마법 / 함정 카드가 발동했을 때, 자신 필드에 "헤블론" 엑시즈 몬스터가 있을 경우
function s.costfilter(c)
	return c:IsSetCard(0xc06) and c:IsType(TYPE_XYZ) and c:GetOverlayCount()>0
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainNegatable(ev) and Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- ① 코스트: 자신 필드의 "헤블론" 엑시즈 몬스터의 엑시즈 소재를 1개 제거
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
	local tg=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_MZONE,0,1,1,nil)
	tg:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ① 타겟: 발동 무효
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- ① 처리: 발동 무효 + 파괴
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- ② 조건: 이 카드가 묘지에 존재하는 상태에서, 자신 필드에 빛 / 어둠 속성 엑시즈 몬스터가 엑시즈 소환되었을 경우
function s.recccon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rc and rc:IsType(TYPE_XYZ) and (rc:IsAttribute(ATTRIBUTE_LIGHT) or rc:IsAttribute(ATTRIBUTE_DARK))
		and rc:IsControler(tp) and re:IsSummonType(SUMMON_TYPE_XYZ)
end

-- ② 타겟: 이 카드 자신 (묘지에서 세트)
function s.reccttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,c,1,0,0)
end

-- ② 처리: 이 카드를 자신 필드에 세트한다. 이 효과로 세트한 이 카드는 필드에서 벗어났을 경우에 제외된다.
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 or not c:IsRelateToEffect(e) then return end
	Duel.SSet(c)
	-- 필드에서 벗어났을 경우 제외되는 지속 효과
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e1:SetProperty(EFFECT_FLAG_WASH_INSTANT)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
	e1:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e1)
end
