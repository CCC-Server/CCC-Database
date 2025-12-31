--대파괴수용결전병기 - 에이펙스 메카도고란 썬더
local s,id=GetID()
function s.initial_effect(c)
	--파괴수 공통 제약 (②)
	c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsSetCard,0xd3),LOCATION_MZONE)

	--①: 릴리스 후 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SPSUM_PARAM)
	e1:SetRange(LOCATION_HAND)
	e1:SetTargetRange(POS_FACEUP_ATTACK,1) -- 기본값: 상대 필드 (sptg에서 변경됨)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--③: 특수 소환 성공 시 서치 (강제)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--④: 카운터 없는 플레이어의 효과 무효 (강제)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_F) -- 강제 효과
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end
s.listed_series={0xd3, 0xc82}

-- ①번 효과
function s.relfilter(c,tp,sc)
	local target_p = c:GetControler()
	-- 1. 릴리스 가능 여부 (SCARD_CHECK_SPPROC 플래그 사용)
	-- 2. 대상 필드(target_p)에 파괴수 고유 제약(1장만 존재) 체크
	-- 3. 대상 필드(target_p)에 몬스터가 나올 공간(MZone)이 있는지 확인 (c가 릴리스되어 사라지는 것 감안)
	-- 주의: sc:IsCanBeSpecialSummoned()를 여기서 호출하면 무한 루프 발생하므로 제거
	return c:IsReleasable(SCARD_CHECK_SPPROC) 
		and s.kaiju_unique_check(sc, target_p, c) 
		and Duel.GetMZoneCount(target_p, c, tp) > 0
end

function s.kaiju_unique_check(c, tp, relcard)
	-- 릴리스할 카드(relcard)를 제외하고 필드에 다른 파괴수가 있는지 확인
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0xd3),tp,LOCATION_MZONE,0,nil)
	if relcard then g:RemoveCard(relcard) end
	return #g == 0
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.relfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp,c)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.relfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp,c)
	if #g>0 then
		local tc=g:GetFirst()
		local target_p = tc:GetControler()
		
		-- [수정됨] SetSPSummonParam -> SetTargetRange 사용
		-- 소환될 위치 설정: 0=자신 필드, 1=상대 필드 (SetTargetRange의 두 번째 인자로 제어)
		local param_p = (target_p==tp) and 0 or 1
		e:SetTargetRange(POS_FACEUP_ATTACK, param_p)
		
		e:SetLabelObject(tc)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local tc=e:GetLabelObject()
	Duel.Release(tc,REASON_COST)
end

-- ③번 효과
function s.thfilter(c)
	return ((c:IsSetCard(0xc82) and c:IsType(TYPE_MONSTER)) or c:IsSetCard(0xd3)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- 강제 효과
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,e:GetHandler():GetOwner(),LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local owner = e:GetHandler():GetOwner()
	Duel.Hint(HINT_SELECTMSG,owner,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(owner,s.thfilter,owner,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-owner,g)
	end
end

-- ④번 효과
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 발동한 플레이어(rp)의 필드에 파괴수 카운터가 있으면 무효화하지 않음
	if Duel.GetCounter(rp,LOCATION_ONFIELD,0,0x37)>0 then return false end
	
	-- 2. 체인 무효화 가능 여부 확인
	if not Duel.IsChainNegatable(ev) then return false end

	-- 3. 발동 위치 체크: "패" 또는 "필드"여야 함 (묘지/제외존 효과는 안 막음)
	local loc = Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	local is_hand_or_field = (loc & (LOCATION_HAND+LOCATION_ONFIELD)) ~= 0
	if not is_hand_or_field then return false end

	-- 4. 대상 카드 체크: "함정" 이거나 "기계족 이외의 몬스터"여야 함
	local rc = re:GetHandler()
	if re:IsActiveType(TYPE_TRAP) then
		return true -- 함정은 종족 상관없이(사실 종족 없지만) 무효
	elseif re:IsActiveType(TYPE_MONSTER) then
		-- 몬스터면 기계족인지 확인
		local race = Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_RACE)
		-- 기계족(RACE_MACHINE)이 아니면(==0) 무효
		return (race & RACE_MACHINE) == 0
	end
	
	return false
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end