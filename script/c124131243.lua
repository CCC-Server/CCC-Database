-- 파이고라 카운터
local s,id=GetID()
function s.initial_effect(c)
    -- Negate and change position
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_POSITION)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_series={0x822}

function s.filter(c)
    return c:IsFaceup() and c:IsRace(RACE_ROCK) and c:IsType(TYPE_FUSION) and c:IsLevelAbove(7)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) and Duel.IsChainNegatable(ev)
        and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_MZONE,0,nil)
    Duel.SetOperationInfo(0,CATEGORY_POSITION,g,1,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
    local tc=g:GetFirst()
    Duel.NegateActivation(ev)
        Duel.ChangePosition(tc,POS_FACEUP_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)
    end
