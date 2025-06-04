--스완송 힘멜
local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon (Water Level 5 x3)
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WATER),5,3)
    c:EnableReviveLimit()

    --①: 자신 필드의 물 속성 몬스터 ATK/DEF +300
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.atktg)
    e1:SetValue(300)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)

    -- New Effect ② implementation
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1)) -- This will be the string ID for the effect description
    e3:SetCategory(CATEGORY_DISABLE) -- This effect negates, so it fits CATEGORY_DISABLE
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O) -- A field effect that grants a Quick Effect
    e3:SetCode(EVENT_FREE_CHAIN) -- Allows activation during any open game state (Quick Effect)
    e3:SetRange(LOCATION_MZONE) -- The effect originates from this card on the monster zone
    e3:SetCountLimit(1) -- Once per turn
    e3:SetCondition(s.has_lvl2_water_material) -- The condition we discussed: must have a Level 2 WATER Xyz material
    e3:SetCost(s.negate_cost) -- Function for detaching material
    e3:SetTarget(s.negate_target) -- Function for targeting opponent's monster
    e3:SetOperation(s.negate_operation) -- Function for negating the target's effects
    c:RegisterEffect(e3)
end

-- ①: 물 속성 몬스터만 공격/수비력 상승 대상
function s.atktg(e,c)
    return c:IsAttribute(ATTRIBUTE_WATER)
end

-- Helper function for Effect ②'s condition
function s.is_lvl2_water(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsLevel(2)
end

-- Condition for Effect ② (the effect itself becomes available if this condition is met)
function s.has_lvl2_water_material(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    -- Check if any Xyz Material of this card is a Level 2 WATER monster
    return c:GetOverlayGroup():IsExists(s.is_lvl2_water, 1, nil)
end

function s.negfilter(c)
    return c:IsFaceup() and c:IsCanBeEffectTarget() and aux.disfilter1(c)
end
-- Cost for Effect ② (detaching 1 material)
function s.negate_cost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:CheckRemoveOverlay(tp, 1, REASON_COST) end
    c:RemoveOverlay(tp, 1, 1, REASON_COST)
end

-- Target for Effect ② (1 opponent's monster)
function s.negate_target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingTarget(s.negfilter, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_NEGATE)
    local g = Duel.SelectTarget(tp, s.negfilter, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetTargetCard(g)
end

-- Operation for Effect ② (negating effects)
function s.negate_operation(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget() -- Get the targeted card
    -- Ensure the card is still face-up and can have its effects disabled
    if tc and tc:IsFaceup() and tc:IsCanDisableEffect() then
        -- Negate the effects of the targeted monster
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE_EFFECT) -- Disables monster effects
        e1:SetReset(RESET_EVENT+RESETS_DISABLE+RESET_PHASE+PHASE_END) -- Negation lasts until the End Phase
        tc:RegisterEffect(e1)
        
        local e2 = Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_TRAPMONSTER) -- Specifically for Trap Monsters whose effects might not be covered by EFFECT_DISABLE_EFFECT
        e2:SetReset(RESET_EVENT+RESETS_DISABLE+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e2)
    end
end