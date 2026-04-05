local s,id=GetID()
function s.initial_effect(c)
	-- ①: 의식 소환 (미츠루기 리추얼 구조 응용)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)

	-- ②: 묘지 회수 효과
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- [의식 소환 관련 필터 및 파라미터]

-- 소환 대상: 사이버스족 의식 몬스터
function s.ritfilter(c)
	return c:IsRace(RACE_CYBERSE) and c:IsRitualMonster()
end

-- 엑스트라 덱 소재 필터: 앞면 표시 몬스터
function s.extramatfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsCanBeRitualMaterial()
end

-- 엑스트라 덱 소재 그룹 가져오기
function s.extragroup(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.extramatfilter,tp,LOCATION_EXTRA,0,nil)
end

-- 의식 소환 파라미터 설정 (미츠루기 리추얼 방식)
function s.get_params(e,tp)
	return {
		filter=s.ritfilter,
		lvtype=RITPROC_GREATER, -- 레벨 이상이 되도록 릴리스
		location=LOCATION_HAND+LOCATION_GRAVE+LOCATION_EXTRA, -- 소환 위치
		extrafil=s.extragroup,
		matfilter=aux.FilterBoolFunction(Card.IsLocation,LOCATION_HAND+LOCATION_MZONE) -- 패/필드 릴리스
	}
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local params=s.get_params(e,tp)
		return Ritual.Target(params)(e,tp,eg,ep,ev,re,r,rp,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_EXTRA)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local params=s.get_params(e,tp)
	Ritual.Operation(params)(e,tp,eg,ep,ev,re,r,rp)
end

-- [②: 묘지 회수 로직]
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsRitualMonster,1,nil)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end