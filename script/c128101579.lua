-- 스타토치 아카데미 커스텀 마법
-- 카드 번호: 128101583 (사용자 파일명에 맞춤)
local s,id=GetID()

function s.initial_effect(c)
	-- ①: 발동 시 효과
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET) -- 대상 지정 가능
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-- 카드군 코드 정의
s.listed_series={0xc57}

-- [필터 함수]
function s.desfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc57) and c:IsMonster()
end
function s.pfilter(c,tp,is_place)
	if not (c:IsSetCard(0xc57) and c:IsType(TYPE_PENDULUM)) then return false end
	if is_place then
		return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
	else
		return c:IsAbleToHand()
	end
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc57) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- [타겟팅 로직]
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.desfilter(chkc) end
	
	-- 기본 발동 조건 체크 (효과 A 혹은 효과 B가 가능한지)
	local b1=Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_DECK,0,1,nil,tp,false) 
		or Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_DECK,0,1,nil,tp,true)
	local b2=Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	
	if chk==0 then return b1 or b2 end

	-- 대상을 선택할 것인지 유저에게 물어봄
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local tg=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)
		e:SetLabel(1) -- 대상을 지정함
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,tg,1,0,0)
	else
		e:SetLabel(0) -- 대상을 지정하지 않음
		e:SetProperty(0) -- 발동 시 대상 지정 속성 제거 (엔진 호환성)
	end
	
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

-- [실행 로직]
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local is_destroyed = false
	
	-- 1. 대상으로 발동했다면 파괴 처리
	if e:GetLabel()==1 and tc and tc:IsRelateToEffect(e) then
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			is_destroyed = true
		end
	end

	-- 2. 가능한 효과 체크
	local b1_hand=Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_DECK,0,1,nil,tp,false)
	local b1_zone=Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_DECK,0,1,nil,tp,true)
	local b2=Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	
	if not (b1_hand or b1_zone or b2) then return end
	
	-- 3. 효과 적용 방식 결정
	local apply_b1 = false
	local apply_b2 = false
	
	-- 파괴되었고 두 효과 모두 가능할 때 '양쪽 모두' 적용 선택 가능
	if is_destroyed and (b1_hand or b1_zone) and b2 then
		if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			apply_b1 = true
			apply_b2 = true
		end
	end
	
	-- 양쪽 적용이 아니면 하나만 선택
	if not (apply_b1 and apply_b2) then
		local sel={}
		local opt={}
		if b1_hand or b1_zone then 
			table.insert(sel,aux.Stringid(id,3)) -- "펜듈럼 서치/배치"
			table.insert(opt,1)
		end
		if b2 then 
			table.insert(sel,aux.Stringid(id,4)) -- "특수 소환"
			table.insert(opt,2)
		end
		
		local choice=Duel.SelectOption(tp,table.unpack(sel))
		if opt[choice+1]==1 then apply_b1=true else apply_b2=true end
	end

	-- 4. 효과 A: 펜듈럼 서치 또는 배치
	if apply_b1 then
		if apply_b2 then Duel.BreakEffect() end
		
		local s1 = b1_hand
		local s2 = b1_zone
		local op2 = 0
		if s1 and s2 then
			op2 = Duel.SelectOption(tp,aux.Stringid(id,5),aux.Stringid(id,6)) -- "패에 넣는다", "P존에 놓는다"
		elseif s1 then
			op2 = 0
		else
			op2 = 1
		end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.pfilter,tp,LOCATION_DECK,0,1,1,nil,tp,op2==1)
		if #g>0 then
			local sc=g:GetFirst()
			if op2==0 then
				Duel.SendtoHand(sc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sc)
			else
				Duel.MoveToField(sc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
			end
		end
	end

	-- 5. 효과 B: 특수 소환
	if apply_b2 then
		if apply_b1 then Duel.BreakEffect() end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end