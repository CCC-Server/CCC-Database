--개굴개굴개구리
local s,id=GetID()
function s.initial_effect(c)
    --①: 묘지 / 제외된 물족 레벨 2 몬스터를 각각 1장씩 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

--공통 특수 소환 제한: 발동 턴 동안 물 속성 몬스터만 특수 소환 가능
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit_general)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end
function s.splimit_general(e,c)
    return not c:IsAttribute(ATTRIBUTE_WATER)
end

--소환 필터: 레벨 2 / 물족 / 물 속성 + 특수 소환 가능
function s.spfilter(c,e,tp)
    return c:IsLevel(2) and c:IsRace(RACE_AQUA) and c:IsAttribute(ATTRIBUTE_WATER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--특수 소환 타겟
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and g:GetClassCount(Card.GetCode)>0 end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 or g:GetClassCount(Card.GetCode)==0 then return end
    local sg=Group.CreateGroup()
    local codes={}
    local ct=0
    while true do
        if ct>=Duel.GetLocationCount(tp,LOCATION_MZONE) then break end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local fg=g:Filter(function(c) return not codes[c:GetCode()] end,nil)
        if #fg==0 then break end
        local tc=fg:Select(tp,1,1,nil):GetFirst()
        if not tc then break end
        sg:AddCard(tc)
        codes[tc:GetCode()] = true
        g:Remove(Card.IsCode,nil,tc:GetCode())
        ct=ct+1
        if #g==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then break end
    end
    if #sg>0 then
        Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)

        --소환 제한 적용: 랭크 4 이상의 물 속성 엑시즈만 특수 소환 가능
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
        e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e2:SetTargetRange(1,0)
        e2:SetTarget(s.splimit_x)
        e2:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e2,tp)
    end
end

--② 특소 제한: 랭크 4 이상의 물 속성 엑시즈만 가능
function s.splimit_x(e,c)
    return not (c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_WATER) and c:GetRank()>=4)
end