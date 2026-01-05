--명계의 저승사자 기온고즈
local s,id=GetID()
function s.initial_effect(c)
	--기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}
	
	--①: 묘지로 보내고 S/T 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_ONFIELD)
	-- 상대 턴에도 시스템이 조건을 상시 체크하도록 타이밍 설정
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetCost(s.setcost)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	
	--②: 데미지 반응 특수 소환 및 반사
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_DAMAGE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--① 효과 조건: 필드에 뒷면 표시 카드가 있으면 프리체인, 없으면 자신 메인 페이즈 기동 효과로만
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	-- 필드에 (자신을 제외한) 뒷면 표시 카드가 존재하는지 확인
	local res=Duel.IsExistingMatchingCard(Card.IsFacedown,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler())
	
	-- 1. 뒷면 카드가 있으면: 상대 턴이든 언제든 발동 가능 (프리체인)
	if res then return true end
	
	-- 2. 뒷면 카드가 없으면: 오직 내 턴 메인 페이즈이며, 체인이 비어있을 때만 (기동 효과 타이밍)
	-- Duel.GetCurrentChain()==0 을 추가하여 뒷면 카드가 없을 땐 다른 효과에 체인할 수 없게 만듭니다.
	return Duel.GetTurnPlayer()==tp and Duel.IsMainPhase() and Duel.GetCurrentChain()==0
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

-- 안전하게 카드명을 체크하는 내부 필터
function s.setfilter(c)
	if not (c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()) then return false end
	
	-- 1. C++ 내부 엔진 함수 사용 (가장 안전)
	if c.ListsCode and c:ListsCode(24857466) then return true end
	
	-- 2. traceback 에러를 방지하기 위해 aux 함수 대신 테이블 직접 참조
	local listed = c.listed_names
	if listed then
		for _,code in ipairs(listed) do
			if code==24857466 then return true end
		end
	end
	return false
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end

--② 효과 로직 (변경 없음)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return ev>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	if ep==tp then
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ev)
	end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		if ep==tp then
			Duel.BreakEffect()
			Duel.Damage(1-tp,ev,REASON_EFFECT)
		end
	end
end