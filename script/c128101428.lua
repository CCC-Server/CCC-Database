--World Guardian ??? (prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- (1) 패에서 특수 소환
	------------------------------------
	-- 1-1) "World Guardian" 필드 마법 컨트롤 시: 메인 페이즈 이그니션
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)          -- 속도 1, 패에서 발동
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)                    -- (1)번 효과 턴 1회 (퀵 버전과 공유)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- 1-2) 필드 존에 필마 + 상대 특소 2장 이상: 프리체인 퀵 효과
	local e1b=e1:Clone()
	e1b:SetType(EFFECT_TYPE_QUICK_O)          -- 퀵 효과
	e1b:SetCode(EVENT_FREE_CHAIN)
	e1b:SetCondition(s.spcon2)
	c:RegisterEffect(e1b)
	
	-- 상대 특소 횟수 체크용 글로벌
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
	
	------------------------------------
	-- (2) 소환 성공 시 서로 1장씩 파괴
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})                -- (2)번 효과 턴 1회
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	------------------------------------
	-- (3) 상대가 몬스터를 일반/특수 소환했을 때, 그 몬스터들 효과 무효 + ATK/DEF 0
	------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})                -- (3)번 효과 턴 1회
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e5)
end

----------------------------------------------------------
-- 글로벌: 각 플레이어가 특수 소환한 몬스터 수 카운트
----------------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	-- eg에 특소된 몬스터 전부 들어있음
	local tc=eg:GetFirst()
	while tc do
		local p=tc:GetSummonPlayer()
		-- 그 플레이어가 특소 1번 할 때마다 플래그 +1
		Duel.RegisterFlagEffect(p,id,RESET_PHASE+PHASE_END,0,1)
		tc=eg:GetNext()
	end
end

----------------------------------------------------------
-- (1) 패에서 특수 소환
----------------------------------------------------------
-- "World Guardian" 필드 마법
function s.wgfieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end
-- 아무 필드 마법 (자신/상대)
function s.anyfieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end

-- (1-1) 조건:
-- 내가 "World Guardian" 필드 마법을 컨트롤
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	return Duel.IsExistingMatchingCard(s.wgfieldfilter,tp,LOCATION_FZONE,0,1,nil)
end

-- (1-2) 조건:
-- 필드 존에 필드 마법 존재 +
-- 상대가 이번 턴에 몬스터를 2장 이상 특소
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	local has_field = Duel.IsExistingMatchingCard(s.anyfieldfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	local opp_ss2 = Duel.GetFlagEffect(1-tp,id)>=2
	return has_field and opp_ss2
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
		-- 이 턴 동안 패에서 "World Guardian" 몬스터 특소 불가
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
-- (2) 서로 1장씩 파괴
----------------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return (chkc:IsOnField() and chkc:IsControler(tp))
			or (chkc:IsOnField() and chkc:IsControler(1-tp))
	end
	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	-- 내가 컨트롤하는 카드 1장 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,0,1,1,nil)
	-- 상대가 컨트롤하는 카드 1장 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,#g1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

----------------------------------------------------------
-- (3) 상대가 몬스터를 일반/특수 소환했을 때, 그 몬스터들 효과 무효 + ATK/DEF 0
----------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 소환한 몬스터가 1장 이상 포함되어 있어야 함
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- 실제 처리는 Operation에서 eg를 그대로 사용
end

function s.negfilter(c,tp)
	return c:IsFaceup() and c:IsSummonPlayer(1-tp)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(s.negfilter,nil,tp)
	if #g==0 then return end
	for tc in aux.Next(g) do
		-- 효과 무효
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
		-- ATK 0
		local e3=e1:Clone()
		e3:SetCode(EFFECT_SET_ATTACK_FINAL)
		e3:SetValue(0)
		tc:RegisterEffect(e3)
		-- DEF 0
		local e4=e1:Clone()
		e4:SetCode(EFFECT_SET_DEFENSE_FINAL)
		e4:SetValue(0)
		tc:RegisterEffect(e4)
	end
end
