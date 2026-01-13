--JJ-쟝 피에르 폴나레프
local s,id=GetID()
function c128220122.initial_effect(c)
Pendulum.AddProcedure(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_EQUIP)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_OATH)
    e2:SetTargetRange(1, 0)
    e2:SetTarget(s.splimit)
    c:RegisterEffect(e2)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsType(TYPE_EFFECT) and not c:IsCode(128220125)
end
function s.filter(c)
    return c:IsCode(128220128)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk == 0 then 
        local c = e:GetHandler()
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
            and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, nil, 1, tp, LOCATION_GRAVE + LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    -- 1. 특수 소환 성공 확인
    if Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
        -- 2. 장착할 카드 선택 (묘지/엑스트라)
        local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.filter), tp, LOCATION_GRAVE+LOCATION_EXTRA, 0, 1, 1, nil)
        local sc = g:GetFirst()
        if sc then
            if sc:IsFacedown() then Duel.ConfirmCards(1-tp, sc) end
            Duel.BreakEffect()
            if Duel.Equip(tp, sc, c) then
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_EQUIP_LIMIT)
                e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e1:SetValue(s.eqlimit)
                e1:SetLabelObject(c)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                sc:RegisterEffect(e1)
                local e2=Effect.CreateEffect(c)
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_CHANGE_TYPE)
                e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e2:SetValue(TYPE_EQUIP+TYPE_SPELL)
                e2:SetReset(RESET_EVENT+RESETS_STANDARD)
                sc:RegisterEffect(e2)
            end
        end
    end
end
function s.eqlimit(e,c)
    return c==e:GetLabelObject()
end