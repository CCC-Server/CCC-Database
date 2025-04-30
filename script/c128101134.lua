--카드명: 트라미드 신규 몬스터 예시
local s,id=GetID()
function s.initial_effect(c)
    --특수 소환 (1)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(EFFECT_LOCATION_HAND)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --파괴 (2)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)

    --필드 마법 교체 (3)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+200)
    e3:SetCondition(s.fmcon)
    e3:SetTarget(s.fmtg)
    e3:SetOperation(s.fmop)
    c:RegisterEffect(e3)
end
s.listed_names={id}
s.listed_series={SET_TRIAMID}
-- (1) 특수 소환 관련
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
end
function s.spcfilter(c)
    return c:IsRace(RACE_ROCK) and c:IsReleasable()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroup(tp,s.spcfilter,1,nil) end
    local g=Duel.SelectReleaseGroup(tp,s.spcfilter,1,1,nil)
    Duel.Release(g,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2) 파괴 효과
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g1=Duel.SelectTarget(tp,aux.FilterFaceupFunction(Card.IsRace,RACE_ROCK),tp,LOCATION_ONFIELD,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g2=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

-- (3) 필드 마법 교체
function s.fmcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()~=tp
end
function s.fmfilter(c,tp)
    return c:IsSetCard(SET_TRIAMID) and c:IsType(TYPE_FIELD) and c:IsAbleToGrave()
        and Duel.IsExistingMatchingCard(s.fmfilter2,tp,LOCATION_DECK,0,1,nil,c:GetCode())
end
function s.fmfilter2(c,code)
    return c:IsSetCard(0xef) and c:IsType(TYPE_FIELD) and not c:IsCode(code)
end
function s.fmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.fmfilter,tp,LOCATION_ONFIELD,0,1,nil,tp) end
end
function s.fmop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.fmfilter,tp,LOCATION_ONFIELD,0,1,1,nil,tp)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
        local code=g:GetFirst():GetCode()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local sg=Duel.SelectMatchingCard(tp,s.fmfilter2,tp,LOCATION_DECK,0,1,1,nil,code)
        if #sg>0 then
            Duel.MoveToField(sg:GetFirst(),tp,tp,LOCATION_FZONE,POS_FACEUP,true)
        end
    end
end
