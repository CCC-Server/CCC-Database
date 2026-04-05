local s,id=GetID()
function s.initial_effect(c)
	-- 펜듈럼 스케일 설정
	Pendulum.AddProcedure(c)
	
	-- 카드군 세트코드 (스타토치: 0xc57)
	local SETCODE_STARTORCH = 0xc57

	-- [펜듈럼 효과] ①: 서치 후 이 카드를 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.phtg)
	e1:SetOperation(s.phop)
	c:RegisterEffect(e1)

	-- [몬스터 효과] ①: 패에서 보여주고 자신+카드군 1장 파괴 후 지속 마함 배치
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- [몬스터 효과] ②: 엑스트라 덱에 앞면으로 보내졌을 경우 특소 + 패 회수
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_DECK)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.excon)
	e3:SetTarget(s.extg)
	e3:SetOperation(s.exop)
	c:RegisterEffect(e3)
end

-- [펜듈럼 ① 함수]
function s.thfilter(c)
	return c:IsSetCard(0xc57) and c:IsMonster() and c:IsAbleToHand()
end
function s.phtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.phop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.BreakEffect()
			Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- [몬스터 ① 함수]
function s.desfilter(c)
	-- 패의 이 카드 이외의 패 / 필드(앞면)의 "스타토치 아카데미" 몬스터
	return c:IsSetCard(0xc57) and c:IsMonster() and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end
function s.tffilter(c)
	return c:IsSetCard(0xc57) and c:IsType(TYPE_CONTINUOUS) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and not c:IsForbidden()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() 
		and Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,c)
		and Duel.IsExistingMatchingCard(s.tffilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,tp,LOCATION_HAND+LOCATION_MZONE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,c)
	if #g>0 then
		g:AddCard(c)
		if Duel.Destroy(g,REASON_EFFECT)==2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
			local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.tffilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
			if tc then
				Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
			end
		end
	end
end

-- [몬스터 ② 함수]
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 엑스트라 덱으로 보내졌을 때 앞면 표시인지 확인
	return c:IsFaceup() and c:IsLocation(LOCATION_EXTRA)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc57) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
		and c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_EXTRA) then
			Duel.BreakEffect()
			Duel.SendtoHand(c,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,c)
		end
	end
end