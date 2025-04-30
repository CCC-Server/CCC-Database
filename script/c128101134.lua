--카드명: 트라미드 신규 몬스터
local s,id=GetID()
function s.initial_effect(c)
    -- (1) 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)  -- ✅ 수정 완료
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --② 자신 + 상대 카드 파괴
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    -- (3) 필드 마법 교체
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

-- (1) 특수 소환 조건
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

--② 자신 + 상대 카드 파괴
function s.selfdesfilter(c)
    return c:IsFaceup() and (c:IsRace(RACE_ROCK) or c:IsType(TYPE_FIELD))
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then
        return Duel.IsExistingTarget(s.selfdesfilter,tp,LOCATION_ONFIELD,0,1,nil)
            and Duel.IsExistingTarget(Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g1=Duel.SelectTarget(tp, function(c) return c:IsFaceup() and (c:IsRace(RACE_ROCK) or c:IsType(TYPE_FIELD)) end, tp, LOCATION_ONFIELD,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g2=Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_ONFIELD,1,1,nil)
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,#g1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end
-- (3) 필드 마법 교체
function s.fmcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()~=tp
end
function s.fmfilter(c,tp)
    return c:IsSetCard(0xef) and c:IsType(TYPE_FIELD) and c:IsAbleToGrave()
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
