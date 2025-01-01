--저승사자의 분노
--Emissary of Darkness' Wrath
local s,id=GetID()
function s.initial_effect(c)
    --Negate activation
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)
    --Indestructible
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.indestg)
    e2:SetValue(1)
    c:RegisterEffect(e2)
end
--Negate activation
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) and Duel.IsChainNegatable(ev)
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,RACE_FIEND)
        and aux.FaceupFilter(Card.IsAttribute,ATTRIBUTE_DARK)
        and aux.FaceupFilter(Card.IsLevelAbove,10),tp,LOCATION_MZONE,0,1,nil)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        Duel.Damage(tp,500,REASON_EFFECT)
    end
end
--Indestructible
function s.indestg(e,c)
    return c:IsRace(RACE_FIEND) and c:IsLevelAbove(7)
end