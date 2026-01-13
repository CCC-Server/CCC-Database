--JJ-실버 채리엇
local s,id=GetID()
local CARD_POLNAREFF = 128220122
function c128220128.initial_effect(c)
Xyz.AddProcedure(c,nil,7,5)
    c:EnableReviveLimit()
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(700)
    c:RegisterEffect(e1)
    local e2_grant = Effect.CreateEffect(c)
    e2_grant:SetDescription(aux.Stringid(id, 0))
    e2_grant:SetCategory(CATEGORY_DESTROY)
    e2_grant:SetType(EFFECT_TYPE_QUICK_O)
    e2_grant:SetCode(EVENT_FREE_CHAIN)
    e2_grant:SetRange(LOCATION_MZONE)
    e2_grant:SetCountLimit(1)
    e2_grant:SetCondition(s.descon)
    e2_grant:SetTarget(s.destg)
    e2_grant:SetOperation(s.desop)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_GRANT)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
    e2:SetTarget(s.granttg)
    e2:SetLabelObject(e2_grant)
    c:RegisterEffect(e2)
end
function s.granttg(e, c)
    return e:GetHandler():GetEquipTarget() == c
end
function s.pol_filter(c)
    return c:IsFaceup() and c:IsCode(CARD_POLNAREFF)
end
function s.descon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(s.pol_filter, tp, LOCATION_ONFIELD, 0, 1, nil)
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(nil, tp, 0, LOCATION_ONFIELD, 1, nil) end
    local g = Duel.GetMatchingGroup(nil, tp, 0, LOCATION_ONFIELD, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectMatchingCard(tp, nil, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
    if #g > 0 then
        Duel.HintSelection(g)
        Duel.Destroy(g, REASON_EFFECT)
    end
end