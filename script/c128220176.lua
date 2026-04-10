--메가록 하디안
local s,id=GetID()
function c128220176.initial_effect(c)
    if not s.global_check then
    s.global_check=true
    local ge1=Effect.CreateEffect(c)
    ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    ge1:SetCode(EVENT_FLIP)
    ge1:SetOperation(s.checkop)
    Duel.RegisterEffect(ge1,0)
end
local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e0:SetCondition(s.actcon)
	c:RegisterEffect(e0)
	
	-- 발동 시 코스트 (세트한 턴에 발동할 경우)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	c:RegisterEffect(e1)
	
	-- ①: 리버스한 상대 몬스터의 효과 무효화
	local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(0, LOCATION_MZONE)
    e2:SetCode(EFFECT_DISABLE) -- 효과 무효
    e2:SetTarget(s.distg)
    c:RegisterEffect(e2)
	
	-- ②: 묘지의 암석족 제외하고 표시 형식 변경
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCost(s.poscost)
	e3:SetTarget(s.postg)
	e3:SetOperation(s.posop)
	c:RegisterEffect(e3)
end

-- 세트한 턴 발동 조건
function s.actcon(e)
	return Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,e:GetHandlerPlayer(),LOCATION_GRAVE,0,1,nil,POS_FACEUP)
		and Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsRace,RACE_ROCK),e:GetHandlerPlayer(),LOCATION_GRAVE,0,1,nil)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	if e:GetHandler():IsStatus(STATUS_SET_TURN) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,aux.FilterBoolFunction(Card.IsRace,RACE_ROCK),tp,LOCATION_GRAVE,0,1,1,nil,Card.IsAbleToRemoveAsCost)
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
end
-- ②번 효과: 표시 형식 변경 (함정이므로 프리체인)
function s.poscostfilter(c)
	return c:IsRace(RACE_ROCK) and c:IsAbleToRemoveAsCost() and c:IsMonster()
end
function s.poscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.poscostfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.poscostfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,0,0)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	if #g>0 then
		local tc=g:GetFirst()
		Duel.ChangePosition(tc,POS_FACEUP_DEFENSE,POS_FACEDOWN_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)
	end
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    for tc in aux.Next(eg) do
        -- 리버스된 몬스터에게 이 카드(id)의 이름으로 플래그를 부여
        tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
    end
end

-- 무효화 대상 판별
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    for tc in aux.Next(eg) do
        -- 특정 카드 ID가 아닌 고유 필드 ID 또는 고정 상수를 사용하는 것이 안전합니다.
        -- 여기서는 단순히 id를 사용하되, distg에서 정확히 체크해야 합니다.
        tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
    end
end

-- 무효화 대상 판별 (수정됨)
function s.distg(e,c)
    return c:GetFlagEffect(id)>0
end