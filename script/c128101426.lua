--World Guardian ??? (prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- 공통: (1)(2)(3) 전부 턴 1회 (각각)
	------------------------------------
	------------------------------------
	-- (1) 패에서 특수 소환
	-- ① 내가 "World Guardian" 필드 마법을 컨트롤하고 있을 때 → 속도 1, 메인페에서 사용
	-- ② 필드 존에 필드 마법이 있고, 이 효과가 체인 링크 3 이상으로 발동될 때 → 퀵 효과
	------------------------------------
	-- 1-1) "World Guardian" 필드 마법 컨트롤 시: 속도 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)	  -- 속도 1
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)				-- (1)번 효과 턴 1회 (퀵 버전과 공유)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- 1-2) 필드 존에 필드 마법 + 체인 링크 3 이상: 퀵 효과
	local e1b=e1:Clone()
	e1b:SetType(EFFECT_TYPE_QUICK_O)	  -- 퀵 효과
	e1b:SetCode(EVENT_FREE_CHAIN)
	e1b:SetCondition(s.spcon2)
	c:RegisterEffect(e1b)
	
	------------------------------------
	-- (2) 소환 성공시 "World Guardian" 특소
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})			-- (2)번 효과 턴 1회
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	------------------------------------
	-- (3) 상대 카드/효과 발동시 무효+제거, 체인 5 이상이면 전멸
	------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})			-- (3)번 효과 턴 1회
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

----------------------------------------------------------
-- 공통 필터
----------------------------------------------------------
-- "World Guardian" 필드 마법
function s.wgfieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end
-- 아무 필드 마법 (자신/상대)
function s.anyfieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end

----------------------------------------------------------
-- (1) 패에서 특수 소환
----------------------------------------------------------
-- 1-1) 조건: 내가 "World Guardian" 필드 마법 컨트롤
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	return Duel.IsExistingMatchingCard(s.wgfieldfilter,tp,LOCATION_FZONE,0,1,nil)
end

-- 1-2) 조건: 필드 존에 필드 마법 + 이 효과가 체인 링크 3 이상으로 발동
-- 체인 링크 N으로 발동되려면, 발동 시점의 Duel.GetCurrentChain()이 N-1이므로
-- "체인 링크 3 이상" → 발동 시점 체인 길이 2 이상
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	return Duel.IsExistingMatchingCard(s.anyfieldfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
		and Duel.GetCurrentChain()>=2
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- "이 효과를 발동한 턴에는 패에서 'World Guardian' 몬스터를 특수 소환할 수 없다."
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- 패에서의 "World Guardian" 몬스터 특소 제한
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER) and c:IsLocation(LOCATION_HAND)
end

----------------------------------------------------------
-- (2) 일소/특소 성공시 "World Guardian" 특소
----------------------------------------------------------
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

----------------------------------------------------------
-- (3) 상대 카드/효과 발동시, "World Guardian" 보내고 무효+제거
-- 체인 링크 5 이상에서 발동했으면 상대 필드 전멸
----------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end

function s.costfilter(c)
	return c:IsSetCard(0xc52) and c:IsAbleToGraveAsCost() and c:IsOnField()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_ONFIELD,0,1,nil)
	end
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=re:GetHandler()
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if rc:IsAbleToRemove() and rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,0,0)
	end
	-- 체인 5 이상일 때를 대비해 상대 필드 파괴 카테고리도 포함
	local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	if #g>0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	-- 발동 무효 + 제거
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
	end
	-- 이 효과가 체인 링크 5 이상으로 발동되어, 현재 해결 중인 체인 길이가 5 이상이면 추가로 전멸
	-- (해결 시점에서 Duel.GetCurrentChain()이 이 효과의 체인 번호)
	if Duel.GetCurrentChain()>=5 then
		local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end
