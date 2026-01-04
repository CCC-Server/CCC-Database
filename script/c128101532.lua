--명계의 저승사자 기온고즈
local s,id=GetID()
function s.initial_effect(c)
	--기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}
	
	--①: 묘지로 보내고 S/T 세트 (유발 즉시 / 기동)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_ONFIELD)
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

--① 효과 조건: 자신 턴이거나, 필드에 뒷면 표시 카드가 존재할 경우
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp or Duel.IsExistingMatchingCard(Card.IsFacedown,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

--[수정됨] 안전한 카드명 기재 확인 함수 (aux.IsCodeListed 대체)
function s.safe_check_listed(c, target_code)
	local codes = c.listed_names
	if not codes then return false end
	for _,code in ipairs(codes) do
		if code==target_code then return true end
	end
	return false
end

--① 효과 필터: "명왕룡 반달기온"이 기재된 마법/함정
function s.setfilter(c)
	--aux.IsCodeListed 대신 s.safe_check_listed 사용
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and s.safe_check_listed(c, 24857466) and c:IsSSetable()
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

--② 효과 조건: 데미지 발생 시
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return ev>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	--자신이 데미지를 입은 경우(ep==tp)에만 데미지 카테고리 정보 포함
	if ep==tp then
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ev)
	end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		--특수 소환 성공 후, 자신이 데미지를 입었었다면 상대에게도 준다
		if ep==tp then
			Duel.BreakEffect()
			Duel.Damage(1-tp,ev,REASON_EFFECT)
		end
	end
end