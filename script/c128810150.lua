--RUM-글로리 오브 헤블론
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 자신 필드의 랭크 4 / 8의 빛 / 어둠 속성 엑시즈 몬스터 1장을 대상으로 하고 발동할 수 있다. 그 몬스터보다 랭크가 4개 높은 빛 / 어둠 속성 엑시즈 몬스터 1장을, 대상 몬스터 위에 겹쳐 엑시즈 소환으로 취급하고 엑스트라 덱에서 특수 소환한다.
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 이 카드가 묘지에 존재하는 상태에서, 자신 필드에 빛 / 어둠 속성 엑시즈 몬스터가 특수 소환되었을 경우에 발동할 수 있다. 이 카드를 패에 넣는다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 타겟: 자신 필드의 랭크 4 / 8의 빛 / 어둠 속성 엑시즈 몬스터 1장
function s.spfilter1(c,e,tp)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and (c:GetRank()==4 or c:GetRank()==8) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
end

function s.spfilter2(c,rk,e,tp)
	return c:IsType(TYPE_XYZ) and c:GetRank()==(rk+4) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.spfilter1(chkc,e,tp) end
	if chk==0 then
		return Duel.IsExistingTarget(s.spfilter1,tp,LOCATION_MZONE,0,1,nil,e,tp)
			and Duel.GetLocationCountFromEx(tp)>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local tc=Duel.SelectTarget(tp,s.spfilter1,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	local rk=tc:GetFirst():GetRank()
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ① 처리: 대상 몬스터 위에 겹쳐 엑시즈 소환으로 취급하고 엑스트라 덱에서 특수 소환한다.
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local rk=tc:GetRank()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_EXTRA,0,1,1,nil,rk,e,tp)
	if #g>0 then
		local sc=g:GetFirst()
		if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)~=0 then
			Duel.Overlay(sc,Group.FromCards(tc))
		end
	end
end

-- ② 조건: 이 카드가 묘지에 존재하는 상태에서, 자신 필드에 빛 / 어둠 속성 엑시즈 몬스터가 특수 소환되었을 경우
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rc and rc:IsFaceup() and rc:IsType(TYPE_XYZ) and (rc:IsAttribute(ATTRIBUTE_LIGHT) or rc:IsAttribute(ATTRIBUTE_DARK)) and rc:IsControler(tp)
end

-- ② 타겟: 이 카드 자신
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end

-- ② 처리: 이 카드를 패에 넣는다.
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end