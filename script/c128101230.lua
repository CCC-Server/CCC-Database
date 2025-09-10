-- A·O·J [가칭] 레벨 12 싱크로
local s,id=GetID()
function s.initial_effect(c)
    -- 싱크로 소환 조건: 기계족 튜너 + 튜너 이외의 기계족 몬스터 1장 이상
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_MACHINE),1,1,
        Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)

    -- ① 싱크로 소환 성공 시: 상대 필드 몬스터 전부 파괴 + 빛 속성 파괴 수만큼 상대 묘지 제외
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.descon)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    -- ② 지속 효과: 자신 필드의 기계족 몬스터는 효과로는 파괴되지 않는다
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_MACHINE))
    e2:SetValue(1)
    c:RegisterEffect(e2)
end

-- ① 조건: 싱크로 소환 성공했을 때만
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

-- ① 상대 필드 몬스터 전부 파괴
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
    if chk==0 then return #g>0 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
    if #g==0 then return end
    local ct=Duel.Destroy(g,REASON_EFFECT)
    if ct>0 then
        -- 파괴된 것 중 빛 속성 확인
        local dg=Duel.GetOperatedGroup():Filter(Card.IsAttribute,nil,ATTRIBUTE_LIGHT)
        local num=#dg
        if num>0 then
            local rg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
            if #rg>0 then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
                local sg=rg:Select(tp,num,num,nil)
                Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end
