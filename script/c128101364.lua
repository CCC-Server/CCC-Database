--Over Limit - (미정 이름, 여기에 실제 카드명 파일명과 맞춰주세요)
local s,id=GetID()

function s.initial_effect(c)
	-- (1) 머신이 있으면 패에서 특소 + 머신 ATK 2배
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	-- "You can only use the (1) and (2) effects of this card's name once per turn."
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- (2) 일반/특소 성공시 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- (3) ATK가 원래 공격력의 2배 이상일 때 효과 파괴 내성
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.protcon)
	e4:SetValue(1)
	c:RegisterEffect(e4)
end

-- "Over Limit" 카드군 / "Limiter Removal"
s.listed_series={0xc48}
local CARD_LIMITER_REMOVAL=23171610
s.listed_names={CARD_LIMITER_REMOVAL}

--------------------------------
-- (1) 패에서 특소 + ATK 2배
--------------------------------
function s.cmachinefilter(c)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE)
end

-- 내가 머신을 조종하고 있을 때만 발동 가능
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cmachinefilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	-- 이 카드 특소
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- 그 후, 머신 1장 ATK 2배 (통상적으로 턴 종료시까지로 처리)
	if not Duel.IsExistingMatchingCard(s.cmachinefilter,tp,LOCATION_MZONE,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tg=Duel.SelectMatchingCard(tp,s.cmachinefilter,tp,LOCATION_MZONE,0,1,1,nil)
	local tc=tg:GetFirst()
	if not tc then return end
	local atk=tc:GetAttack()
	if atk<0 then atk=0 end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	-- “double the ATK” → 현재 공격력을 2배로, 턴 종료시까지
	e1:SetValue(atk*2)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
end

--------------------------------
-- (2) 세트할 카드 필터
-- "Over Limit" 함정 또는 "Limiter Removal"
--------------------------------
function s.setfilter(c)
	return ((c:IsSetCard(0xc48) and c:IsType(TYPE_TRAP)) or c:IsCode(CARD_LIMITER_REMOVAL))
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	-- 세트
	if Duel.SSet(tp,tc)>0 then
		Duel.ConfirmCards(1-tp,tc)
		-- 만약 세트된 카드가 "Limiter Removal" 이면, 그 턴 바로 발동 가능
		if tc:IsCode(CARD_LIMITER_REMOVAL) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end

--------------------------------
-- (3) ATK가 원래 공격력의 2배 이상이면
-- 효과 파괴 내성
--------------------------------
function s.protcon(e)
	local c=e:GetHandler()
	local atk=c:GetAttack()
	local batk=c:GetBaseAttack()
	if batk<0 then batk=0 end
	return atk>=batk*2
end
