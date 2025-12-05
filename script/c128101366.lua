-- Over Limit - Yaroeyasik Striker
local s,id=GetID()
local CARD_LIMITER_REMOVAL=23171610

-- "리미터 해제" / 그것으로 취급되는 마/함 공통 체크
local function IsLimiterRemovalSpellTrap(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and (c:IsCode(CARD_LIMITER_REMOVAL) or c:ListsCode(CARD_LIMITER_REMOVAL)) -- 수정됨
end

function s.initial_effect(c)
	-- 링크 소환 조건
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,2,s.lcheck)

	-- (1) 링크 소환 성공시
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.lkcon)
	-- (1)/(2) 중 1개만, 턴당 1번
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	-- (2) "Limiter Removal" 발동 시 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	-- 이그잼 기어처럼 데미지 스텝/계산에서도 반응하도록
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)

	-- (3) 내성
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.protcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.protcon)
	e4:SetValue(aux.tgoval)
	c:RegisterEffect(e4)
end

-- "Over Limit" / "Limiter Removal"
s.listed_series={0xc48}
s.listed_names={CARD_LIMITER_REMOVAL}

-------------------------------------------------
-- 링크 소재 관련
-------------------------------------------------
function s.matfilter(c)
	return c:IsRace(RACE_MACHINE)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(s.olmatfilter,1,nil)
end
function s.olmatfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsSetCard(0xc48) and c:GetAttack()>=3000
end

-------------------------------------------------
-- (1) 링크 소환 조건 / 처리
-------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.machinefilter(c)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE)
end
function s.lrgyfilter(c)
	return c:IsCode(CARD_LIMITER_REMOVAL)
end
function s.searchfilter(c)
	return (c:IsCode(CARD_LIMITER_REMOVAL)
		or (c:IsSetCard(0xc48) and c:IsType(TYPE_SPELL+TYPE_TRAP)))
		and c:IsAbleToHand()
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.machinefilter,tp,LOCATION_MZONE,0,1,nil)
	end
	local g=Duel.GetMatchingGroup(s.machinefilter,tp,LOCATION_MZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,tp,LOCATION_MZONE)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.machinefilter,tp,LOCATION_MZONE,0,nil)
	if #g==0 then return end

	-- 전부 ATK 2배
	for tc in aux.Next(g) do
		local atk=tc:GetAttack()
		if atk<0 then atk=0 end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(atk*2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end

	-- 엔드 페이즈에 한 번만 파괴
	local eg2=g:Clone()
	eg2:KeepAlive()
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetCountLimit(1)
	e2:SetLabelObject(eg2)
	e2:SetOperation(s.desop)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)

	-- GY에 Limiter Removal 있으면 서치
	if not Duel.IsExistingMatchingCard(s.lrgyfilter,tp,LOCATION_GRAVE,0,1,nil) then return end
	if not Duel.IsExistingMatchingCard(s.searchfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) then return end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.searchfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if g then
		Duel.Destroy(g,REASON_EFFECT)
		g:DeleteGroup()
	end
end

-------------------------------------------------
-- (2) "Limiter Removal" 이 발동되었을 때 세트
-------------------------------------------------
-- 체인 올라온 카드(또는 코드 리스트에 등록된 카드)가
-- 23171610(리미터 해제)이면 OK
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then return false end
	local rc=re:GetHandler()
	return IsLimiterRemovalSpellTrap(rc)
end

-- 세트 대상:
--  - 마법/함정
--  - 세트 가능
--  - "Limiter Removal"을 언급하는 카드(Card.ListsCode)
--    또는 "Limiter Removal" 자체
function s.setfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsSSetable()
		and (c:IsCode(CARD_LIMITER_REMOVAL) or c:ListsCode(CARD_LIMITER_REMOVAL)) -- 수정됨
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	if Duel.SSet(tp,tc)>0 then
		Duel.ConfirmCards(1-tp,tc)
		-- 세트된 카드는 이 턴에도 발동 가능
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		if tc:IsType(TYPE_TRAP) then
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		else
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		end
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-------------------------------------------------
-- (3) ATK가 원래 공격력의 2배 이상이면 내성
-------------------------------------------------
function s.protcon(e)
	local c=e:GetHandler()
	local atk=c:GetAttack()
	local batk=c:GetBaseAttack()
	if batk<0 then batk=0 end
	return atk>=batk*2
end