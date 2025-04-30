--Tramid Revenge of Sphinx
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()

    -- 특수 소환 제한: "트라미드" 카드 효과 또는 이 카드 자신의 효과로만
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetValue(function(e,se,sp,st)
        return se and (se:GetHandler():IsSetCard(0xe2) or se:GetHandler()==e:GetHandler())
    end)
    c:RegisterEffect(e0)

    --① 패에서 특수 소환 (자신/상대 메인 페이즈, 암석족 릴리스)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
    e1:SetCountLimit(1,id)
    e1:SetCondition(function(e,tp) return Duel.IsMainPhase() end)
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

    --③ 상대 턴에 트라미드 필드 마법 교체
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+200)
    e3:SetCondition(function(e,tp) return Duel.GetTurnPlayer()~=tp end)
    e3:SetTarget(s.fldtg)
    e3:SetOperation(s.fldop)
    c:RegisterEffect(e3)
end

--① 릴리스 비용
function s.cfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_ROCK) and c:IsReleasable()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroup(tp,s.cfilter,1,nil) end
    local g=Duel.SelectReleaseGroup(tp,s.cfilter,1,1,nil)
    Duel.Release(g,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
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

--③ 트라미드 필드 마법 교체
function s.fldfilter(c,tp)
    return c:IsFaceup() and c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD)
        and Duel.IsExistingMatchingCard(s.fldnewfilter,tp,LOCATION_DECK,0,1,nil,c:GetCode(),tp)
end
function s.fldnewfilter(c,code,tp)
    return c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD) and not c:IsCode(code)
        and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.fldtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.fldfilter,tp,LOCATION_ONFIELD,0,1,nil,tp) end
end
function s.fldop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.SelectMatchingCard(tp,s.fldfilter,tp,LOCATION_ONFIELD,0,1,1,nil,tp)
    local tc=g:GetFirst()
    if tc and Duel.SendtoGrave(tc,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_GRAVE) then
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local sg=Duel.SelectMatchingCard(tp,s.fldnewfilter,tp,LOCATION_DECK,0,1,1,nil,tc:GetCode(),tp)
        if #sg>0 then
            Duel.ActivateFieldSpell(sg:GetFirst(),e,tp)
        end
    end
end
