--셀레스티얼 타이탄-현자 에아
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 조건
	Synchro.AddProcedure(c,
		aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),1,1,
		aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),1,99)
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c)
	-- E1: 펜듈럼 존 세팅
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.pztg)
	e1:SetOperation(s.pzop)
	c:RegisterEffect(e1)

	-- E2: 서치 (메인 페이즈 1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc02}
s.listed_names={id}

-- 공통 소환 제한
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA)
		and not (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsType(TYPE_SYNCHRO))
end

function s.applylimit(e,tp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- 펜듈럼 필터
function s.pzfilter(c)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM)
end

-- 이름 중복 제한
function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetCode)==#sg
end

-- E1 타겟
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 펜듈럼 존의 빈칸 확인 (마스터 룰 4 이후 방식)
		return (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1))
			and Duel.IsExistingMatchingCard(s.pzfilter,tp,LOCATION_DECK,0,1,nil)
	end
end

-- E1 실행 (완전 수정본: 호환성 극대화)
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 빈 펜듈럼 존 확인
	local ft=0
	if Duel.CheckLocation(tp,LOCATION_PZONE,0) then ft=ft+1 end
	if Duel.CheckLocation(tp,LOCATION_PZONE,1) then ft=ft+1 end
	if ft<=0 then return end

	-- 2. 덱에서 '셀레스티얼 타이탄' 펜듈럼 몬스터 수집
	local g=Duel.GetMatchingGroup(s.pzfilter,tp,LOCATION_DECK,0,nil)
	if #g==0 then return end

	-- 3. 이름이 중복되지 않게 수동으로 선택
	local sg=Group.CreateGroup()
	for i=1,ft do
		-- 이미 선택한 카드와 이름이 다른 카드들만 필터링
		local temp_g=g:Filter(function(c) 
			return not sg:IsExists(Card.IsCode,1,nil,c:GetCode()) 
		end,nil)
		
		if #temp_g==0 then break end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local sc=temp_g:Select(tp,1,1,nil)
		if #sc>0 then
			sg:Merge(sc)
		end
	end
	
	-- 4. 선택된 카드들을 필드에 배치
	if #sg>0 then
		local tc=sg:GetFirst()
		while tc do
			local zone=0
			if Duel.CheckLocation(tp,LOCATION_PZONE,0) then zone=0 else zone=1 end
			Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true,1<<zone)
			tc=sg:GetNext()
		end
		s.applylimit(e,tp) -- 공통 제약 적용
	end
end

-- 메인 페이즈 1 조건
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

-- 서치 필터
function s.thfilter(c)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM)
		and (c:IsLocation(LOCATION_DECK) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
		and c:IsAbleToHand()
end

-- E2 대상
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end

-- E2 실행
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		s.applylimit(e,tp)
	end
end