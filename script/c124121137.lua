-- 제너럴 마스터 데몬
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 자신 / 상대 스탠바이 페이즈 또는 엔드 페이즈에 500 LP 지불하고 패에서 특수 소환. 
	-- 그 후 데몬 마/함 또는 팬더모니엄 서치/세트. (특소된 카드는 공격 불가, 엔드 페이즈 파괴)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SET)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) -- 월아룡의 페이즈 유발 효과 방식 적용
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- 엔드 페이즈에도 동일하게 발동할 수 있도록 복제
	local e2=e1:Clone()
	e2:SetCode(EVENT_PHASE+PHASE_END)
	c:RegisterEffect(e2)

	-- ②: 효과로 파괴되었을 경우, 묘지/제외 상태의 다른 "데몬" 카드 1장을 패로 회수
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+1) -- 구버전 호환을 위해 id+1 사용
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end
s.listed_names={94585852,id} -- 팬더모니엄-악마의 소굴-, 제너럴 마스터 데몬
s.listed_series={0x45} -- 데몬

-- [① 코스트] 500 LP 지불
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,500) end
	Duel.PayLPCost(tp,500)
end

-- [① 서치/세트할 카드 필터]
function s.thfilter(c)
	return ((c:IsSetCard(0x45) and c:IsType(TYPE_SPELL+TYPE_TRAP)) or c:IsCode(94585852))
		and (c:IsAbleToHand() or c:IsSSetable())
end

-- [① 타겟 지정]
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- [① 효과 처리]
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. 월아룡의 방식처럼 SpecialSummonStep을 사용하여 소환된 몬스터에게 효과를 부여
	if c:IsRelateToEffect(e) and Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP) then
		-- 디메리트 1: 공격할 수 없다
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3206) -- "공격할 수 없다"는 엔진 기본 클라이언트 힌트
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1,true)
		
		-- 디메리트 2: 엔드 페이즈에 파괴된다
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetCode(EVENT_PHASE+PHASE_END)
		e2:SetCountLimit(1)
		e2:SetRange(LOCATION_MZONE)
		e2:SetOperation(s.desop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2,true)
	end
	Duel.SpecialSummonComplete()
	
	-- 2. 특수 소환 성공 후 처리: 서치 또는 세트 (천배룡 파이도라 로직)
	if c:IsLocation(LOCATION_MZONE) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local tc=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
		if tc then
			aux.ToHandOrElse(tc,tp,
				Card.IsSSetable,
				function(sc)
					Duel.SSet(tp,sc)
				end,
				aux.Stringid(id,2) -- "세트한다" 옵션 텍스트 번호
			)
		end
	end
end

-- [① 파괴 효과 실행 함수]
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end

-- [② 샐비지 조건] 효과 파괴
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end

-- [② 샐비지 필터]
function s.gyfilter(c)
	return c:IsSetCard(0x45) and not c:IsCode(id) and c:IsAbleToHand()
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

-- [② 타겟 지정]
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.gyfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.gyfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.gyfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

-- [② 효과 처리]
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end