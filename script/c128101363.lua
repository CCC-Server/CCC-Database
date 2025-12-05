--Over Limit - Sonic Disaster
local s,id=GetID()
-- "Limiter Removal"
local CARD_LIMITER_REMOVAL=23171610

function s.initial_effect(c)
	-- 링크 소환 설정
	c:EnableReviveLimit()
	-- 2 Machine 몬스터, 포함해서 최소 1장은 "Over Limit" 몬스터
	Link.AddProcedure(c,s.matfilter,2,2,s.lcheck)

	--------------------------------
	-- 전역 체크: 이 턴에 "Limiter Removal" 발동 기록
	--------------------------------
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end

	--------------------------------
	-- ①: 머신 1장 ATK 3000으로
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id) -- ① 효과 턴당 1번
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②: 이 턴에 리미터 해제가 발동되었다면
	--	 묘지에서 "Over Limit" 몬스터 특소
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1) -- ② 효과 턴당 1번
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--------------------------------
	-- ③: ATK가 원래 공격력의 2배 이상일 때
	--	 효과 파괴 내성
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.protcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
end

-- "Over Limit" 카드군
s.listed_series={0xc48}
-- Limiter Removal
s.listed_names={CARD_LIMITER_REMOVAL}

-------------------------------------------------
-- 링크 소재 관련
-------------------------------------------------
-- 소재는 Machine 몬스터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_MACHINE,lc,sumtype,tp)
end
-- 포함해서 최소 1장은 "Over Limit" 몬스터
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0xc48,lc,sumtype,tp)
end

-------------------------------------------------
-- 전역 체크: 이 턴에 "Limiter Removal" 발동 여부
-------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsCode(CARD_LIMITER_REMOVAL) then
		-- 리미터 해제를 발동한 플레이어에게 턴 종료까지 플래그
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

-------------------------------------------------
-- ①: 머신 1장 ATK 3000으로
-------------------------------------------------
function s.atkfilter(c,tp)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsControler(tp)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and s.atkfilter(chkc,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.atkfilter,tp,LOCATION_MZONE,0,1,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.atkfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,1,0,0)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- 텍스트에 턴 제한이 없으므로 영구적으로 3000으로 설정
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(3000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-------------------------------------------------
-- ②: 이 턴에 "Limiter Removal" 이 발동되어 있으면
--	 묘지에서 "Over Limit" 몬스터 특소
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 이 턴에 리미터 해제를 발동한 적이 있는지 체크
	return Duel.GetFlagEffect(tp,id)>0
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc48) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-------------------------------------------------
-- ③: ATK가 원래 공격력의 2배 이상일 때 효과 파괴 내성
-------------------------------------------------
function s.protcon(e)
	local c=e:GetHandler()
	local atk=c:GetAttack()
	local batk=c:GetBaseAttack()
	if batk<0 then batk=0 end
	return atk>=batk*2
end
