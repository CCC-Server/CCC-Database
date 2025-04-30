--카드명: 트라미드 넥서리온 스핑크스
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --융합 소환 조건
    Fusion.AddProcMix(c,true,true,s.ffilter1,s.ffilter2)

    -- 특수 소환 제한
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- 필드의 몬스터 + 필드 마법으로 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- (1) 특수 소환 시 필드 마법 발동
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCountLimit(1,id)
    e2:SetOperation(s.activatefield)
    c:RegisterEffect(e2)

    -- (2) 자신의 카드가 묘지로 갈 경우 상대 카드 제외
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id+100)
    e3:SetCondition(s.rmcon)
    e3:SetTarget(s.rmtg)
    e3:SetOperation(s.rmop)
    c:RegisterEffect(e3)
end
s.listed_names={id}
s.listed_series={SET_TRIAMID}
-- 융합 소재
function s.ffilter1(c,fc,sumtype,tp)
    return c:IsSetCard(SET_TRIAMID)  -- 트라미온 또는 트라미드
end
function s.ffilter2(c,fc,sumtype,tp)
    return c:IsRace(RACE_ROCK)
end

-- 특수 소환 제한: 융합 또는 지정 방식만 가능
function s.splimit(e,se,sp,st)
    return se:IsHasType(EFFECT_TYPE_ACTION) or e:GetHandler():IsLocation(LOCATION_EXTRA)
end

-- 특수 소환 조건: 트라미드 몬스터 + 트라미온 + 필드 마법 묘지로
function s.spfilter1(c)
    return c:IsSetCard(SET_TRIAMID) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
end
function s.spfilter2(c)
    return c:IsSetCard(SET_TRIAMID) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
end
function s.spfilter3(c)
    return c:IsType(TYPE_FIELD) and c:IsAbleToGraveAsCost()
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_ONFIELD,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g2=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_ONFIELD,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g3=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_ONFIELD,0,1,1,nil)
    g1:Merge(g2)
    g1:Merge(g3)
    Duel.SendtoGrave(g1,REASON_COST)
end

-- (1) 특수 소환 성공 시: 트라미온 필드 마법 발동
function s.fieldfilter(c,tp)
    return c:IsType(TYPE_FIELD) and c:IsSetCard(SET_TRIAMID) and not c:IsForbidden()
        and c:CheckActivateEffect(false,true,false)~=nil
end
function s.activatefield(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,s.fieldfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tp)
    local tc=g:GetFirst()
    if tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
    end
end

-- (2) 자신의 카드가 묘지로 → 상대 카드 제외
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsControler,1,nil,tp)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    end
end
