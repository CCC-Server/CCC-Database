--Aero Maneuver - Split Typhoon
local s,id=GetID()
function s.initial_effect(c)
	-- 카드군 표기용
	-- 0xc49 = "Aero Maneuver"
	-- 0xc50 = "Fight Call"
	s.listed_series={0xc49,0xc50}

	--------------------------------
	-- (1) 패에서 특수 소환
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	-- 이 카드명 (1)번의 특수 소환은 1턴에 1번만
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 소환 성공시 "Fight Call" 덤핑 / 바운스 시 추가 서치
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	-- 이 카드명 (2)번 효과는 1턴에 1번만
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

--------------------------------
-- 상수
--------------------------------
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50	  -- "Fight Call"

--------------------------------
-- (1) 패에서 특수 소환 조건
-- "자신 필드에 몬스터가 없거나, 상대 몬스터가 더 많을 경우"
--------------------------------
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	local my=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
	local op=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	return my==0 or my<op
end

--------------------------------
-- (2) 코스트 : 이 카드를 패로 되돌릴지 선택 (선택 코스트)
-- "또한, 이 카드를 패로 되돌리고 이 효과를 발동할 수도 있다"
--------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return true end
	e:SetLabel(0) -- 기본값 : 되돌리지 않음
	if c:IsRelateToEffect(e) and c:IsFaceup() and c:IsAbleToHandAsCost()
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		e:SetLabel(1) -- 되돌림 선택
		Duel.SendtoHand(c,nil,REASON_COST)
	end
end

--------------------------------
-- (2) 덱에서 "Fight Call" 1장 묘지로
--------------------------------
function s.fcfilter(c)
	return c:IsSetCard(SET_FIGHTCALL) and c:IsAbleToGrave()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fcfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

--------------------------------
-- (2) 추가 서치 대상 : 비튜너 레벨 3 WIND 몬스터
--------------------------------
function s.addfilter(c)
	return c:IsLevel(3) and c:IsAttribute(ATTRIBUTE_WIND)
		and not c:IsType(TYPE_TUNER)
		and c:IsMonster() and c:IsAbleToHand()
end

--------------------------------
-- (2) 처리 : "Fight Call" 덤핑 → (바운스했으면) 비튜너 L3 WIND 서치
-- 이후 : WIND 이외 전부 특소 불가 + 엑스트라는 엑시즈만
--------------------------------
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- 덱에서 "Fight Call" 카드 1장 묘지로 보냄
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.fcfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end

	-- 이 카드를 패로 되돌린 상태였다면, 비튜너 레벨 3 WIND 몬스터 서치 가능
	if e:GetLabel()==1
		and Duel.IsExistingMatchingCard(s.addfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.addfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end

	-- 이 턴 동안 WIND 이외 특수 소환 불가
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit_wind)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- 또한, 엑스트라 덱에서는 엑시즈 몬스터만 특수 소환 가능
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetDescription(aux.Stringid(id,4))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimit_xyz)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

-- WIND 이외 특수 소환 봉인
function s.splimit_wind(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsAttribute(ATTRIBUTE_WIND)
end

-- 엑스트라 덱에서 엑시즈 이외 특소 봉인
function s.splimit_xyz(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_XYZ)
end
