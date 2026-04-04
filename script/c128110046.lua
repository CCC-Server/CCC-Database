-- H-C(히로익 챔피언) XX(듀얼 엑스)-칼리버
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환 조건: "히로익" 몬스터를 포함하는 전사족 레벨 4 몬스터 × 2
	c:EnableReviveLimit()
	-- 매그넘 엑스칼리버 규격 참고: Xyz.AddProcedure(카드, 필터, 레벨, 소재수, ..., 그룹체크)
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_WARRIOR),4,2,nil,nil,nil,nil,false,s.xyzcheck)

	-- ①: 자신 / 상대 턴에 2번까지, 공격력이 원래 공격력 이상일 경우 소재 1개 제거하고 공격력 배
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(2,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_BATTLE_START)
	e1:SetCondition(s.atkcon)
	e1:SetCost(s.atkcost)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	-- ②: 자신 LP가 500 이하인 한 지속 효과 적용
	-- ● 상대는 배틀 페이즈 중 효과 발동 불가
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.limcon)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)
	-- ● 자신 필드의 "H-C" 몬스터는 상대가 발동한 효과를 받지 않음
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetCondition(s.limcon)
	e3:SetTarget(s.immtg)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- ③: 수비 표시 공격 시 배의 관통 데미지
	-- 기본 관통 효과 부여
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e4)
	-- 관통 데미지 발생 시 2배로 수치 변경
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e5:SetCondition(s.damcon)
	e5:SetOperation(s.damop)
	c:RegisterEffect(e5)
end

s.listed_series={0x106f} -- 히로익

-- 엑시즈 소재 그룹 체크: 그룹 내에 "히로익" 카드군(0x106f)이 최소 1장 존재해야 함
function s.xyzcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0x106f)
end

-- ① 공격력 배 효과 조건
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetAttack()>=c:GetBaseAttack()
end

-- ① 소재 제거 코스트
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ① 공격력 배 처리 (턴 종료 시까지)
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(c:GetAttack()*2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end

-- ② LP 500 이하 조건 판정
function s.limcon(e)
	return Duel.GetLP(e:GetHandlerPlayer())<=500
end

-- ②-1 배틀 페이즈 발동 제한
function s.aclimit(e,re,tp)
	return Duel.IsBattlePhase()
end

-- ②-2 "H-C(히로익 챔피언)" 필터: 히로익(0x206f)이면서 엑시즈인 몬스터
function s.immtg(e,c)
	return c:IsSetCard(0x206f) and c:IsType(TYPE_XYZ)
end

-- ②-2 상대가 발동한 효과 내성
function s.efilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- ③ 관통 데미지 배 조건: 데미지가 발생하고 대상이 수비 표시일 때
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return Duel.GetBattleDamage(1-tp)>0 and bc and bc:IsDefensePos()
end

-- ③ 데미지 수치 2배 변경
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeBattleDamage(1-tp,Duel.GetBattleDamage(1-tp)*2)
end