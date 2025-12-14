--대파괴수용결전병기 - 에이펙스 메카도고란 썬더
local s,id=GetID()
function s.initial_effect(c)
	--파괴수 공통 제약 (②)
	c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsSetCard,0xd3),LOCATION_MZONE)

	--①: 릴리스 후 특수 소환 (자신/상대 필드 릴리스 -> 그 플레이어 필드에 소환)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SPSUM_PARAM)
	e1:SetRange(LOCATION_HAND)
	e1:SetTargetRange(POS_FACEUP_ATTACK,1) -- 기본값(무시됨, Operation에서 재설정)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--③: 특수 소환 성공 시 원래 주인이 서치 (강제 효과)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--④: 카운터 없는 플레이어의 효과 발동 무효 (기계족 패/필드 제외)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end
s.listed_series={0xd3, 0xc82} -- 파괴수, 대괴수결전병기

-- ①번 효과 구현
function s.relfilter(c,tp,sc)
	-- 릴리스 가능 여부 + 해당 위치에 소환 시 파괴수 1장 제약(Unique) 체크
	-- 자신이 릴리스되면 자신 필드(tp)에 소환, 상대가 릴리스되면 상대 필드(1-tp)에 소환
	local target_p = c:GetControler()
	return c:IsReleasable(SCARD_CHECK_SPPROC) and s.kaiju_unique_check(sc, target_p, c) 
		and sc:IsCanBeSpecialSummoned(nil,0,tp,false,false,POS_FACEUP_ATTACK,target_p)
end

function s.kaiju_unique_check(c, tp, relcard)
	-- 릴리스할 카드를 제외하고 필드에 다른 파괴수가 있는지 확인
	-- (파괴수는 자신 필드에 1장만 존재 가능하므로, 릴리스할 카드가 유일한 파괴수라면 소환 가능)
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0xd3),tp,LOCATION_MZONE,0,nil)
	if relcard then g:RemoveCard(relcard) end
	return #g == 0
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- 자신 또는 상대 필드의 몬스터 중 조건을 만족하는 카드가 있어야 함
	return Duel.IsExistingMatchingCard(s.relfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp,c)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.relfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp,c)
	if #g>0 then
		local tc=g:GetFirst()
		local target_p = tc:GetControler()
		
		-- 소환될 플레이어 위치 설정 (릴리스한 몬스터의 컨트롤러 필드)
		-- 0: 자신 필드, 1: 상대 필드 (SetSPSummonParam의 두 번째 인자)
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

-- ③번 효과 구현
function s.thfilter(c)
	return (c:IsSetCard(0xc82) and c:IsType(TYPE_MONSTER)) or c:IsSetCard(0xd3)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- 강제 효과
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,e:GetHandler():GetOwner(),LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- 효과 처리 시, "원래 주인"을 기준으로 서치
	local owner = e:GetHandler():GetOwner()
	Duel.Hint(HINT_SELECTMSG,owner,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(owner,s.thfilter,owner,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-owner,g)
	end
end

-- ④번 효과 구현
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- 발동한 플레이어(rp)의 필드에 파괴수 카운터가 없어야 함
	-- 0x37: 파괴수 카운터
	if Duel.GetCounter(rp,1,0,0x37)>0 then return false end
	
	-- 몬스터 효과 또는 함정 카드여야 함
	if not re:IsActiveType(TYPE_MONSTER+TYPE_TRAP) then return false end
	
	-- 예외: 패/필드에서 발동한 기계족 몬스터 효과는 무효 불가
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	local rc=re:GetHandler()
	if re:IsActiveType(TYPE_MONSTER) and rc:IsRace(RACE_MACHINE) and (loc==LOCATION_HAND or loc==LOCATION_ONFIELD) then
		return false
	end
	
	return Duel.IsChainNegatable(ev)
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