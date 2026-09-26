--나츄르의 휴영
local s,id=GetID()
function s.initial_effect(c)
	--카드 발동 (필드에 표시)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--①: 자신 메인 페이즈에 덱/패에서 레벨 2 이하의 "나츄르" 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--②: 이 카드가 묘지로 보내졌을 경우에 발동할 수 있다.
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end
s.listed_series={0x2a} -- "나츄르" 카드군 코드

-- ①번 효과: 특수 소환 가능 여부 확인
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2a) and c:IsLevelBelow(2) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-- ①번 효과: 특수 소환 처리 및 맹세/내성 디메리트 적용
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 제약 1: 상대 턴 종료시까지, 자신은 몬스터를 통상 소환할 수 없다.
		-- (0번 스트링을 클라이언트 힌트로 표시)
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetTargetRange(1,0)
		e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		Duel.RegisterEffect(e1,tp)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_MSET)
		e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET) -- 힌트 중복 표시 방지
		Duel.RegisterEffect(e2,tp)

		-- 제약 2: 상대 턴 종료시까지, 자신 필드의 레벨 2 이하의 "나츄르" 몬스터는 상대 효과의 대상이 되지 않는다.
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e3:SetTargetRange(LOCATION_MZONE,0)
		e3:SetTarget(s.indtg)
		e3:SetValue(aux.tgoval)
		e3:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		Duel.RegisterEffect(e3,tp)

		-- (1번 스트링을 클라이언트 힌트로 표시하는 표시 전용 효과)
		local e4=Effect.CreateEffect(c)
		e4:SetDescription(aux.Stringid(id,1))
		e4:SetType(EFFECT_TYPE_FIELD)
		e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e4:SetTargetRange(1,0)
		e4:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		Duel.RegisterEffect(e4,tp)
	end
end

function s.indtg(e,c)
	return c:IsSetCard(0x2a) and c:IsLevelBelow(2)
end

-- ②번 효과: 같은 이름의 카드가 자신 필드(앞면)/묘지에 존재하는지 확인
function s.cfilter(c,code)
	return (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE)) and c:IsCode(code)
end
-- ②번 효과: 필드에 놓을 수 있는지 확인
-- 필드 마법: 룰에 따라 그냥 놓을 수 있음 (기존 필드 마법은 룰로 묘지로 보내짐)
-- 지속 마법/함정: 빈 마법 & 함정 존이 있어야 함
function s.canplace(c,tp)
	if c:IsForbidden() or not c:CheckUniqueOnField(tp) then return false end
	if c:IsType(TYPE_FIELD) then return true end
	return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end
-- ②번 효과: 덱에서 고를 수 있는 "나츄르" 지속 마법 / 필드 마법 / 지속 함정
function s.plfilter(c,tp)
	if not c:IsSetCard(0x2a) then return false end
	local isfield=c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
	local iscont=c:IsType(TYPE_CONTINUOUS) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
	if not (isfield or iscont) then return false end
	if Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,c:GetCode()) then return false end
	return c:IsAbleToGrave() or s.canplace(c,tp)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK,0,1,nil,tp)
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD or HINTMSG_TOGRAVE)
	local tc=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if not tc then return end
	local b1=s.canplace(tc,tp)
	local b2=tc:IsAbleToGrave()
	-- 1: 자신 필드에 앞면 표시로 놓는다 / 2: 묘지로 보낸다
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,2)},
		{b2,aux.Stringid(id,3)})
	if op==1 then
		if tc:IsType(TYPE_FIELD) then
			-- 이미 필드 마법이 있으면 룰에 따라 묘지로 보내고 놓는다
			local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
			if fc then
				Duel.SendtoGrave(fc,REASON_RULE)
			end
			Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		else
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	elseif op==2 then
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end
end
