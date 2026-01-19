--어둠의 일족의 석가면
local s,id=GetID()
function c128220148.initial_effect(c)
     aux.AddEquipProcedure(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_CHANGE_RACE)
    e1:SetCondition(s.notillusioncon)
    e1:SetValue(RACE_ZOMBIE)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_DISABLE)
    e2:SetCondition(s.notillusioncon)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_EQUIP)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetCondition(s.illusioncon)
    e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_EQUIP)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCountLimit(1, id)
    e4:SetCondition(s.spcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end
s.setname = 0xc27
function s.notillusioncon(e)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and not ec:IsRace(RACE_ILLUSION)
end
function s.illusioncon(e)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsRace(RACE_ILLUSION)
end
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return s.notillusioncon(e)
end
function s.spfilter(c, e, tp)
    return c:IsSetCard(s.setname) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 -- 장착 카드가 될 공간 확인
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local old_ec = c:GetEquipTarget()
    if not c:IsRelateToEffect(e) or not old_ec or old_ec:IsFacedown() then return end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
    local new_ec = g:GetFirst()

    if new_ec and Duel.SpecialSummon(new_ec, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        Duel.Equip(tp, c, new_ec)
        if Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 then
            Duel.BreakEffect()
            if not Duel.Equip(tp, old_ec, new_ec) then return end
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetValue(s.ecatcheck)
            e1:SetLabelObject(new_ec)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            old_ec:RegisterEffect(e1)
        end
    end
end
function s.ecatcheck(e, c)
    return e:GetLabelObject() == c
end