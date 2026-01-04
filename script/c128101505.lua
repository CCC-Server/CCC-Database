-- No.53 위해신 Heart-eartH - 리부트
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환
	Xyz.AddProcedure(c,nil,5,2)
	c:EnableReviveLimit()

	-- 카드명 기재 ("가비지 로드", "No.92 위해신룡 Heart-eartH Dragon")
	s.listed_names={44682448, 47017574}

	-- ①: 이 카드가 엑시즈 소환에 성공했을 경우, 이 카드의 엑시즈 소재를 1개 제거하고 발동할 수 있다. 
	-- 덱에서 "가비지 로드"의 카드명이 쓰여진 카드 1장을 패에 넣는다. 그 후, 묘지에서 "가비지 로드" 1장을 특수 소환할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetCost(s.thcost) -- 코스트 추가
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: 공격 대상으로 선택됐을 경우. 공격 몬스터의 원래 공격력만큼 공격력 증가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BE_BATTLE_TARGET)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- ③: 효과로 필드를 벗어났을 경우 또는 소재 없이 공격 대상이 되었을 경우.
	-- "No.92" 엑시즈 취급 특소 + 묘지의 이 카드를 소재로 함
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCountLimit(1,id+2)
	e3:SetCondition(s.spcon1)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e4)
	local e5=e3:Clone()
	e5:SetCode(EVENT_TO_DECK)
	c:RegisterEffect(e5)
	local e6=e3:Clone()
	e6:SetCode(EVENT_TO_HAND)
	c:RegisterEffect(e6)
	
	-- ③의 추가 트리거: 소재 없이 공격 대상이 됨
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetCode(EVENT_BE_BATTLE_TARGET)
	e7:SetCountLimit(1,id+2)
	e7:SetCondition(s.spcon2)
	e7:SetTarget(s.sptg2)
	e7:SetOperation(s.spop2)
	c:RegisterEffect(e7)
end

-- 관련 카드 코드
local CARD_GARBAGE_LORD = 44682448
local CARD_NO_92 = 47017574

-- [안전한 확인 함수] 카드명 기재 여부 확인
function s.is_listed_safe(c, code)
	if not c then return false end
	if c.IsCodeListed and c:IsCodeListed(code) then return true end
	if c.listed_names then
		for _,v in ipairs(c.listed_names) do
			if v==code then return true end
		end
	end
	return false
end

-- ① 효과: 엑시즈 소환 성공 시 조건
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

-- ① 효과: 코스트 (엑시즈 소재 1개 제거)
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ① 효과 필터: "가비지 로드" 카드명 기재 카드
function s.thfilter(c)
	return s.is_listed_safe(c, CARD_GARBAGE_LORD) and c:IsAbleToHand()
end

-- ① 효과 필터: "가비지 로드" 본체 특소
function s.spfilter_gl(c,e,tp)
	return c:IsCode(CARD_GARBAGE_LORD) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ① 효과 Target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_GRAVE)
end

-- ① 효과 Operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
			-- 그 후 묘지 특소 처리 (가비지 로드 본체)
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter_gl),tp,LOCATION_GRAVE,0,1,nil,e,tp)
				and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then 
				
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter_gl),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
				Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

-- ② 효과 Target
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=Duel.GetAttacker()
	if chk==0 then return tc and tc:IsFaceup() end
	tc:CreateEffectRelation(e)
end

-- ② 효과 Operation
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetAttacker()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local atk=tc:GetBaseAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end

-- ③ 효과 조건 1: 효과로 필드를 벗어남
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsReason(REASON_EFFECT)
end

-- ③ 효과 조건 2: 소재 0 + 공격 대상
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()==0
end

-- ③ 효과 필터: "No.92"
function s.spfilter92(c,e,tp)
	return c:IsCode(CARD_NO_92) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

-- ③ 효과 Target
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_XYZ)>0
		and Duel.IsExistingMatchingCard(s.spfilter92,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ③ 효과 Operation
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter92,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)~=0 then
		-- "묘지의 이 카드를" 소재로 함
		if c:IsLocation(LOCATION_GRAVE) and not c:IsHasEffect(EFFECT_NECRO_VALLEY) then
			Duel.Overlay(tc, c)
		end
	end
end