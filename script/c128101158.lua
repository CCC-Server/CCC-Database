-- A・O・J 차지 필드 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- 기본 활성화 (지속 함정 특유)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ① 상대 몬스터를 빛 속성으로 변경 (지속 효과)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(0,LOCATION_MZONE)
	e1:SetCondition(s.attrcon)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsFaceup))
	e1:SetValue(ATTRIBUTE_LIGHT)
	c:RegisterEffect(e1)

	-- ② 기계족 싱크로 수만큼 파괴 (퀵 발동 / 1턴 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_ALLY_OF_JUSTICE}

-- ① 조건: 내 필드에 A.O.J 싱크로 몬스터 존재 여부
function s.attrcon(e)
	return Duel.IsExistingMatchingCard(function(c)
		return c:IsFaceup() and c:IsSetCard(SET_ALLY_OF_JUSTICE) and c:IsType(TYPE_SYNCHRO)
	end, e:GetHandlerPlayer(), LOCATION_MZONE, 0, 1, nil)
end

-- ② 조건: 상대 필드 카드 최대 X장 대상 (내 필드+묘지 기계족 싱크로 수)
function s.cfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsType(TYPE_SYNCHRO)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() end
	local ct = Duel.GetMatchingGroupCount(s.cfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if chk==0 then return ct > 0 and Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g = Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
