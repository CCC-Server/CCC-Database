--Tramid Alchemist
local s,id=GetID()
function s.initial_effect(c)
    --①: 특수 소환 (패에서)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --②: 소환 성공 시 서치
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    --③: 상대 턴에 필드 마법 교체
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,2})
    e4:SetCondition(s.qcon)
    e4:SetTarget(s.qtg)
    e4:SetOperation(s.qop)
    c:RegisterEffect(e4)
end

s.listed_names={id}
s.listed_series={0xe2}

--① 특소 조건
function s.cfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_ROCK) and not c:IsCode(id)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--② 덱에서 "트라미드" 몬스터 서치
function s.thfilter(c)
    return c:IsSetCard(0xe2) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--③ 상대 턴에 트라미드 필드 마법 교체
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()~=tp
end
function s.fdfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD) and c:IsAbleToGrave()
end
function s.fdset(c,tp)
    return c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD) and c:GetActivateEffect()
        and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.fdfilter,tp,LOCATION_ONFIELD,0,1,nil)
            and Duel.IsExistingMatchingCard(s.fdset,tp,LOCATION_DECK,0,1,nil,tp)
    end
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.fdfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local sg=Duel.SelectMatchingCard(tp,s.fdset,tp,LOCATION_DECK,0,1,1,nil,tp)
        if #sg>0 then
            local tc=sg:GetFirst()
            local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
            if fc then Duel.SendtoGrave(fc,REASON_RULE) end
            Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
            local te=tc:GetActivateEffect()
            if te then
                te:UseCountLimit(tp,1,true)
                local cost=te:GetCost()
                if cost then cost(te,tp,eg,ep,ev,re,r,rp,1) end
                Duel.RaiseEvent(tc,EVENT_CHAIN_SOLVING,e,REASON_EFFECT,tp,tp,ev)
            end
        end
    end
end
