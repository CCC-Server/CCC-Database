--검투수 프로보카토르
local s,id=GetID()
function s.initial_effect(c)
	-- (1) 패에서 보여주고 발동: 덱의 검투수(이 카드 제외)를 상대 필드에 특소 & 자신 특소
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- (2) 소환 성공 시 서치
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- (3) 배틀 페이즈 종료 시 덱으로 되돌리고 덱 특소 (검투수 공통 태그 아웃)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e4:SetRange(LOCATION_MZONE)
	-- (3)번 효과 턴 제약 없음
	e4:SetCondition(s.tagcon)
	e4:SetCost(s.tagcost)
	e4:SetTarget(s.tagtg)
	e4:SetOperation(s.tagop)
	c:RegisterEffect(e4)
end

-- 검투수 카드군 코드 (요청하신 0x1019 적용)
local SET_GLADIATOR_BEAST = 0x1019
s.listed_series={SET_GLADIATOR_BEAST}
s.listed_names={id}

--------------------------------------------------------------------------------
-- (1) 효과 구현
--------------------------------------------------------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	Duel.ConfirmCards(1-tp,e:GetHandler())
end
function s.spfilter(c,e,tp)
	-- 소환 타입을 113(검투수 효과 소환)으로 체크
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsType(TYPE_MONSTER) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,113,tp,false,false,POS_FACEUP_DEFENSE,1-tp)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
		and c:IsCanBeSpecialSummoned(e,113,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 상대 필드에 검투수(이 카드 제외) 특수 소환
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		-- ★ 수정: 소환 타입을 113으로 변경 (검투수 효과 발동 조건 충족) ★
		if Duel.SpecialSummon(g,113,tp,1-tp,false,false,POS_FACEUP_DEFENSE)>0 then
			-- 성공 시 자신 필드에 이 카드 특수 소환
			if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				Duel.SpecialSummon(c,113,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- (2) 효과 구현
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------------------------------------------------
-- (3) 효과 구현
--------------------------------------------------------------------------------
function s.tagcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetBattledGroupCount()>0
end
function s.tagcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeckAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.tagfilter(c,e,tp)
	-- 소환 타입을 113으로 체크
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,113,tp,false,false)
end
function s.tagtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetMZoneCount(tp,e:GetHandler())>0
		and Duel.IsExistingMatchingCard(s.tagfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.tagop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.tagfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		-- ★ 수정: 소환 타입을 113으로 변경 ★
		Duel.SpecialSummon(g,113,tp,tp,false,false,POS_FACEUP)
	end
end