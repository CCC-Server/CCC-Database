-- 대괴수결전병기 - 제토 쟈가
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 소환 유발 (서치)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- ②: 파괴/제외 대신 묘지에서 덱으로 되돌리기
	-- 파괴 대체
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
	-- 제외 대체 (Send Replace)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_SEND_REPLACE)
	e4:SetTarget(s.banreptg)
	e4:SetValue(s.banrepval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end
s.listed_names={56111151} -- KYOUTOU 워터프론트 (코드 수정됨)
s.listed_series={0xc72, 0xd3} -- 대괴수결전병기, 파괴수

-- ① 효과: 서치 필터 (파괴수 마/함)
function s.thfilter(c)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
-- ① 효과: 서치 필터 (워터프론트)
function s.kyoutoufilter(c)
	return c:IsCode(56111151) and c:IsAbleToHand() -- 코드 수정됨
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		
		-- 필드 존 확인 및 워터프론트 추가 서치
		local field_card=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if not field_card then
			local g2=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.kyoutoufilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
			if #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local sg=g2:Select(tp,1,1,nil)
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end

-- ② 효과: 보호 대상 필터
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD)
		and (c:IsSetCard(0xd3) or c:IsCode(56111151)) -- 파괴수 또는 워터프론트 (코드 수정됨)
		and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

-- ② 효과: 파괴 대체 Target
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToDeck() and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end

-- ② 효과: 제외 대체 Target (EFFECT_SEND_REPLACE)
function s.banreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToDeck() and eg:IsExists(s.repfilter,1,nil,tp)
			and (r&REASON_EFFECT)~=0 -- 효과에 의한 이동
			and (r&REASON_REDIRECT)==0 -- 지속물/룰에 의한 제외가 아님
	end
	if Duel.SelectEffectYesNo(tp,c,96) then
		return true
	end
	return false
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.banrepval(e,c)
	return false 
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SendtoDeck(e:GetHandler(),nil,2,REASON_EFFECT+REASON_REPLACE)
end