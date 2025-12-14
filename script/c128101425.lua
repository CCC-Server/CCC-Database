--World Guardian (prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- (1) 패에서 특수 소환
	------------------------------------
	-- 1-1) "World Guardian" 필드 마법 컨트롤 시: 메인 페이즈 한정, 속도 1
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
	-- 1-2) 필드 존에 필드 마법 + 상대 몬스터 효과 5회 이상: 프리 체인 퀵 효과
	local e1b=e1:Clone()
	e1b:SetType(EFFECT_TYPE_QUICK_O)	  -- 퀵 효과
	e1b:SetCode(EVENT_FREE_CHAIN)
	e1b:SetCondition(s.spcon2)
	c:RegisterEffect(e1b)
	
	-- 상대 몬스터 효과 발동 횟수 세는 글로벌 효과
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
	
	------------------------------------
	-- (2) 일소/특소 성공시 서치 & 회수
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})			 -- (2)번 효과 턴 1회
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	------------------------------------
	-- (3) 선언한 카드 타입에 대해, 상대가 발동할 때마다 500 데미지
	------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})			 -- (3)번 효과 턴 1회
	e4:SetTarget(s.lptg)
	e4:SetOperation(s.lpop)
	c:RegisterEffect(e4)
end

----------------------------------------------------------
-- 글로벌: 상대가 발동한 몬스터 효과 횟수 카운트
----------------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_MONSTER) then
		-- 해당 플레이어(rp)가 몬스터 효과를 1번 발동할 때마다 플래그 +1
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

----------------------------------------------------------
-- (1) 패에서 특수 소환 관련
----------------------------------------------------------
-- "World Guardian" 필드 마법 체크
function s.wgfieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end
-- 아무 필드 마법 체크 (자신/상대)
function s.anyfieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end

-- (1-1) 조건: 내가 "World Guardian" 필드 마법을 컨트롤 + 메인 페이즈
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	local ph=Duel.GetCurrentPhase()
	if ph~=PHASE_MAIN1 and ph~=PHASE_MAIN2 then return false end
	return Duel.IsExistingMatchingCard(s.wgfieldfilter,tp,LOCATION_FZONE,0,1,nil)
end

-- (1-2) 조건: 필드 존에 필드 마법 존재 + 상대 몬스터 효과 5회 이상 (프리 체인)
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	return Duel.IsExistingMatchingCard(s.anyfieldfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
		and Duel.GetFlagEffect(1-tp,id)>=5
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
-- (2) 일소/특소 성공시 서치 & 회수
----------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

----------------------------------------------------------
-- (3) 선언한 카드 타입에 대해, 상대가 발동할 때마다 500 데미지
----------------------------------------------------------
function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- 타입 선언: 0 = 몬스터, 1 = 마법, 2 = 함정
	local opt=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4),aux.Stringid(id,5))
	e:SetLabel(opt) -- 나중에 Operation에서 사용
end

function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local opt=e:GetLabel()
	local declared_type
	if opt==0 then
		declared_type=TYPE_MONSTER
	elseif opt==1 then
		declared_type=TYPE_SPELL
	else
		declared_type=TYPE_TRAP
	end
	
	-- 남은 턴 동안, 상대가 해당 타입 카드/효과를 발동할 때마다 500 데미지
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(0)
	e1:SetLabel(declared_type)
	e1:SetOperation(s.damop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- 상대가 선언한 타입의 카드/효과를 발동할 때마다 500 데미지
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local t=e:GetLabel()  -- TYPE_MONSTER / TYPE_SPELL / TYPE_TRAP
	if rp~=1-tp then return end
	local tc=re:GetHandler()
	if tc:IsType(t) and re:IsActiveType(t) then
		Duel.Damage(1-tp,500,REASON_EFFECT)
	end
end
