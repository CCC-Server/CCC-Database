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
	e1:SetTargetRange(POS_FACEUP_ATTACK,1) 
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
	return c:IsReleasable(SCARD_CHECK_SPPROC) and s.kaiju_unique_check(sc, target_p, c) 
		and sc:IsCanBeSpecialSummoned(nil,0,tp,false,false,POS_FACEUP_ATTACK,target_p)
end

function s.kaiju_unique_check(c, tp, relcard)
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
		local param_p = (target_p==tp) and 0 or 1
		e:SetSPSummonParam(POS_FACEUP_ATTACK, param_p)
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
	if chk==0 then return true end
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

	-- 3. 함정 카드면 무조건 발동 (위치 상관 없음)
	if re:IsActiveType(TYPE_TRAP) then return true end

	-- 4. 몬스터 효과인 경우: "패 또는 필드"에서 발동했고 AND "기계족이 아닐 경우"에만 발동
	if re:IsActiveType(TYPE_MONSTER) then
		local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
		local race=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_RACE)
		
		-- 위치가 패(LOCATION_HAND) 또는 필드(LOCATION_ONFIELD) 인지 확인 (비트 연산)
		local is_hand_or_field = (loc & (LOCATION_HAND+LOCATION_ONFIELD)) ~= 0
		
		-- 종족이 기계족이 아닌지 확인 (비트 연산)
		local is_not_machine = (race & RACE_MACHINE) == 0
		
		-- 패/필드에서 발동한 비-기계족 몬스터라면 무효화
		if is_hand_or_field and is_not_machine then
			return true
		end
	end
	
	-- 그 외(마법, 묘지/제외존 몬스터 효과, 패/필드의 기계족 몬스터 효과)는 무효화하지 않음
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