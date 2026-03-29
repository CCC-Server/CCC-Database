--붉은 눈의 흉격
local s,id=GetID()
function s.initial_effect(c)

	-----------------------------------------------------------
	-- ① 패/필드 1장 덱으로 되돌리고 → 레벨 7 이하 "붉은 눈" 서치 or 특소
	-----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)		  -- 속공마법 발동
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)				  -- ① 효과 타깃 설정
	e1:SetOperation(s.activate)			 -- ① 실제 처리
	c:RegisterEffect(e1)

	-----------------------------------------------------------
	-- ② 묘지에서 발동 / "붉은 눈" 몬스터 효과 발동 시 트리거
	--  묘지의 이 카드를 제외하고
	--  자신의 패/S·T의 "붉은 눈" 카드 1장을 파괴 → 대상 몬스터 효과 무효 + 선택적 파괴
	-----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)			  -- 효과 발동이 체인에 올랐을 때
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)			 -- 묘지에서 발동
	e2:SetCountLimit(1,id)				  -- 이 카드명의 ②는 1턴 1번
	e2:SetCondition(s.discon)			   -- 발동 조건: 자신이 "붉은 눈" 몬스터 효과 발동
	e2:SetCost(s.discost)				   -- 코스트: 묘지의 이 카드 제외
	e2:SetTarget(s.distg)				   -- 타깃 지정
	e2:SetOperation(s.disop)				-- 처리
	c:RegisterEffect(e2)
end

-- "붉은 눈" 세트 코드 정의
s.listed_series={0x3b}

-----------------------------------------------------------
-- ① 덱/묘지에서 레벨 7 이하 "붉은 눈" 몬스터 선택 조건
-----------------------------------------------------------
function s.filter(c,ft,e,tp)
	return c:IsLevelBelow(7)
		and c:IsSetCard(0x3b)								 -- "붉은 눈" 세트
		and (c:IsAbleToHand()								  -- 패에 넣을 수 있고
			or (ft>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false))) -- 특소 가능
end

-----------------------------------------------------------
-- ① 덱으로 되돌릴 패/필드 카드 필터
-- 이 카드명 자신(e:GetHandler())은 제외해야 함
-----------------------------------------------------------
function s.tdfilter(c,e)
	-- IsAbleToDeckAsCost()를 사용하여 필드를 벗어날 예정인 마함 자동 제외
	return not c:IsCode(e:GetHandler():GetCode()) and c:IsAbleToDeckAsCost()
		and (c:IsLocation(LOCATION_HAND) or c:IsFaceup()) -- 패이거나 필드 앞면 표시
end

-----------------------------------------------------------
-- ① 타깃 설정
-----------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		-- (1) 서치/특소 가능한 "붉은 눈"이 덱 or 묘지에 존재?
		-- (2) 패/필드 1장이 덱으로 되돌릴 수 있는가? (이 카드 자신 제외)
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,ft,e,tp)
			and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil,e)
	end
	-- 덱으로 되돌리는 정보 (패/필드)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD)
	-- 특수 소환 / 패로 서치 중 한 가지가 가능함을 알림
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-----------------------------------------------------------
-- ① 실제 처리
-- 패/필드 1장 덱으로 → "붉은 눈" Lv7 이하를 패 or 특소
-----------------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 효과 처리 시점에 덱으로 돌릴 카드 다시 검색 (이 카드 자신 제외)
	local rg=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,nil,e)
	
	-- 돌릴 카드가 없다면 처리 불가능
	if #rg==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local srg=rg:Select(tp,1,1,nil)
	local sc=srg:GetFirst()
	
	-- 필드의 카드를 선택했다면 보여줌
	if sc:IsLocation(LOCATION_ONFIELD) then
		Duel.HintSelection(srg)
	end
	
	-- 덱으로 되돌림
	if Duel.SendtoDeck(sc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		-- 덱으로 되돌리기 성공 시 처리
		
		-- 덱/묘지 후보 검색을 위해 몬스터 존 여유 다시 계산 (필드 카드 되돌렸을 수 있으므로)
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,ft,e,tp)

		if #g>0 then
			local th=g:GetFirst():IsAbleToHand()
			local sp=ft>0 and g:GetFirst():IsCanBeSpecialSummoned(e,0,tp,false,false)

			-- 플레이어에게 선택권 제공
			local op=0
			if th and sp then
				op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1)) -- 패로 / 특소 선택
			elseif th then
				op=0
			else
				op= op==1 and op or 1 -- 안전장치
				op=1
			end

			-- 결과 처리
			if op==0 then
				Duel.SendtoHand(g,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,g)
			else
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

-----------------------------------------------------------
-- ② 파괴할 자신의 "붉은 눈" 카드 필터
-----------------------------------------------------------
function s.discostfilter(c)
	-- 패이거나 필드 앞면 표시 "붉은 눈" 카드
	return c:IsSetCard(0x3b) and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

-----------------------------------------------------------
-- ② 발동 조건: 자신이 "붉은 눈" 몬스터의 효과를 발동했을 경우
-----------------------------------------------------------
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	-- 조건: 체인의 주체가 "붉은 눈" 몬스터이며, 그 효과의 발동 주체가 나(tp)
	return rp==tp and rc:IsSetCard(0x3b) and re:IsActiveType(TYPE_MONSTER)
end

-----------------------------------------------------------
-- ② 코스트: 묘지의 이 카드를 제외
-----------------------------------------------------------
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-----------------------------------------------------------
-- ② 타깃 설정
-----------------------------------------------------------
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsNegatableMonster() and chkc:IsLocation(LOCATION_MZONE)
	end

	if chk==0 then
		-- (1) 무효화 가능한 필드 몬스터 존재?
		-- (2) 파괴할 자신의 "붉은 눈" 카드 존재?
		return Duel.IsExistingTarget(Card.IsNegatableMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
			and Duel.IsExistingMatchingCard(s.discostfilter,tp,LOCATION_HAND+LOCATION_SZONE,0,1,nil)
	end

	-- 무효화할 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,Card.IsNegatableMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)

	-- 효과 무효 및 파괴 정보 등록
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_SZONE)
end

-----------------------------------------------------------
-- ② 실제 처리
-----------------------------------------------------------
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget() -- 무효화 대상

	-- 파괴할 자신의 "붉은 눈" 카드 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.discostfilter,tp,LOCATION_HAND+LOCATION_SZONE,0,1,1,nil)

	if #g>0 then
		Duel.HintSelection(g)
		if Duel.Destroy(g,REASON_EFFECT)>0 then  -- 파괴 성공 시
			
			if tc:IsRelateToEffect(e) and tc:IsNegatableMonster() then
				-- 체인 무효
				Duel.NegateRelatedChain(tc,RESET_TURN_SET)

				-- ■ 몬스터 효과 무효화 부여
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESETS_STANDARD_PHASE_END)
				tc:RegisterEffect(e1)

				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetValue(RESET_TURN_SET)
				e2:SetReset(RESETS_STANDARD_PHASE_END)
				tc:RegisterEffect(e2)

				Duel.AdjustInstantly(tc)

				-- ■ 무효화된 몬스터를 추가로 파괴할지 선택
				if tc:IsDisabled() and tc:IsRelateToEffect(e) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					Duel.BreakEffect()
					Duel.Destroy(tc,REASON_EFFECT)
				end
			end
		end
	end
end