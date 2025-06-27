local s,id=GetID()
function s.initial_effect(c)
	-- 융합 소환 조건
   c:EnableReviveLimit()
	--Fusion Summon procedure
	Fusion.AddProcMix(c,true,true,s.matfilter,aux.FilterBoolFunctionEx(Card.IsSetCard,0x175))

	-- ①: LP 절반 지불하고 효과 제한 부여
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- ②: LP 비교로 공격 / 마법 봉쇄
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(s.lpcon)
	c:RegisterEffect(e2)
local e3=Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_FIELD)
e3:SetCode(EFFECT_CANNOT_ACTIVATE)
e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
e3:SetRange(LOCATION_MZONE)
e3:SetTargetRange(0,1)
e3:SetCondition(s.lpcon)
e3:SetValue(s.aclimit)
c:RegisterEffect(e3)

	-- ③: 파괴 시 다이놀피어 부활
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

function s.matfilter(c,fc,sumtype,tp)
	return c:IsType(TYPE_FUSION,fc,sumtype,tp) and c:IsSetCard(0x175,fc,sumtype,tp)
end
-- ①: LP 절반 지불
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,math.floor(Duel.GetLP(tp)/2)) end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_ACTIVATE_COST)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTarget(s.aclimit_target)
	e1:SetCost(s.aclimit_cost2)
	e1:SetOperation(s.aclimit_op2)
	Duel.RegisterEffect(e1,tp)
end

function s.aclimit_target(e,te,tp)
	return true -- 어떤 카드든 제한 적용
end
function s.aclimit_cost2(e,te,tp)
	return Duel.CheckLPCost(tp,300)
end
function s.aclimit_op2(e,tp,eg,ep,ev,re,r,rp)
	Duel.PayLPCost(tp,300)
end

-- ②: 자신의 LP < 상대 LP 일 때
function s.lpcon(e)
	return Duel.GetLP(e:GetHandlerPlayer()) < Duel.GetLP(1-e:GetHandlerPlayer())
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_SPELL)
end

-- ③: 파괴되었을 때 다이놀피어 부활
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_BATTLE+REASON_EFFECT)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x175) and c:IsLevelBelow(6) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

