--World Guardian ??? (prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- (1) 패에서 특수 소환
	------------------------------------
	-- 1-1) 내가 "World Guardian" 필드 마법을 컨트롤하고 있을 때: 기동 효과
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)            -- 속도 1, 패에서 발동
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)                      -- (1)번 효과 턴 1회 (트리거 버전과 공유)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- 1-2) 필드 존에 필드 마법이 있고, 상대 패에 카드가 들어갔을 때: 트리거 효과
	local e1b=e1:Clone()
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1b:SetCode(EVENT_TO_HAND)
	e1b:SetCondition(s.spcon2)
	c:RegisterEffect(e1b)
	
	------------------------------------
	-- (2) 소환 성공시 "World Guardian" 세트
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(0)                           -- CATEGORY_TOFIELD 는 에드로에 없음 → 0으로 변경
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})                  -- (2)번 효과 턴 1회
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	------------------------------------
	-- (3) 상대가 엑스트라 덱에서 특수 소환했을 때 파괴+번
	------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})                  -- (3)번 효과 턴 1회
	e4:SetCondition(s.excon)
	e4:SetTarget(s.extg)
	e4:SetOperation(s.exop)
	c:RegisterEffect(e4)
end

----------------------------------------------------------
-- 공통 필터
----------------------------------------------------------
function s.tohandfilter(c,p)
	return c:IsControler(p)
end

----------------------------------------------------------
-- (1) 패에서 특수 소환 관련
----------------------------------------------------------
-- "World Guardian" 필드 마법
function s.wgfieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end
-- 아무 필드 마법 (자신/상대)
function s.anyfieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
end

-- (1-1) 조건: 내가 "World Guardian" 필드 마법을 컨트롤
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	return Duel.IsExistingMatchingCard(s.wgfieldfilter,tp,LOCATION_FZONE,0,1,nil)
end

-- (1-2) 조건:
-- 필드 존에 필드 마법 존재 + 드로우 페이즈가 아니고 +
-- 이번 이벤트로 상대 패에 카드가 추가됨
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetCurrentPhase()==PHASE_DRAW then return false end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	if not Duel.IsExistingMatchingCard(s.anyfieldfilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil) then
		return false
	end
	-- eg 안에 상대 패로 들어간 카드가 있는지 체크
	return eg:IsExists(s.tohandfilter,1,nil,1-tp)
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
-- (2) "World Guardian" 마/함 세트
----------------------------------------------------------
function s.setfilter(c)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
	-- 카테고리는 0이라 굳이 OperationInfo 안 줘도 되지만, 써도 무방
	-- Duel.SetOperationInfo(0,CATEGORY_TOFIELD,nil,1,tp,LOCATION_DECK) -- 사용 안 함
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	-- 필드 꽉 차는 특수 상황은 IsSSetable()로 대부분 걸러지지만, 필요하면 추가 체크 가능
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SSet(tp,tc)
	end
end

----------------------------------------------------------
-- (3) 상대가 엑덱에서 특수 소환했을 때, 그 중 1장을 파괴하고 1000 데미지
----------------------------------------------------------
function s.exsummonfilter(c,tp)
	return c:IsFaceup() and c:IsSummonPlayer(1-tp) and c:IsSummonLocation(LOCATION_EXTRA)
end
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	-- 데미지 스텝 제외
	if Duel.GetCurrentPhase()==PHASE_DAMAGE and Duel.IsDamageCalculated() then return false end
	return eg:IsExists(s.exsummonfilter,1,nil,tp)
end
function s.extg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return eg:IsContains(chkc) and s.exsummonfilter(chkc,tp)
	end
	if chk==0 then
		return eg:IsExists(s.exsummonfilter,1,nil,tp)
	end
	local g=eg:Filter(s.exsummonfilter,nil,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local dg=g:Select(tp,1,1,nil)
	Duel.SetTargetCard(dg)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,dg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.Destroy(tc,REASON_EFFECT)~=0 then
			Duel.Damage(1-tp,1000,REASON_EFFECT)
		end
	end
end
