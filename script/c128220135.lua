--JJ-같은 타입의 스탠드
local s,id=GetID()
function c128220135.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1, id + EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end
function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0xc26)
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk, ch)
    if chk == 0 then return Duel.IsExistingTarget(s.filter, tp, LOCATION_MZONE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, s.filter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    e:SetCategory(CATEGORY_DESTROY)
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    -- 대상 몬스터가 필드에 앞면 표시로 존재할 경우에만 처리
    if tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local atk = tc:GetAttack()
        local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
        local dg = g:Filter(function(c) return c:GetAttack() <= atk end, nil)
        if #dg > 0 then
            Duel.Destroy(dg, REASON_EFFECT)
        end
    end
end