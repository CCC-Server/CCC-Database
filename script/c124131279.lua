--Arcana Force ∅ - The Zeros Death
local s,id=GetID()
function s.initial_effect(c)
    --Link summon restriction
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,1,1)
    --Special summon limit
    c:SetSPSummonOnce(id)
    --Coin toss effect
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_COIN)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetTarget(s.cointg)
    e1:SetOperation(s.coinop)
    c:RegisterEffect(e1)
    --Return all graveyard cards and draw
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.tdcon)
    e2:SetTarget(s.tdtg)
    e2:SetOperation(s.tdop)
    c:RegisterEffect(e2)
    --Set ATK to 2300
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_SET_ATTACK)
    e3:SetCondition(s.atkcon)
    e3:SetValue(2300)
    c:RegisterEffect(e3)
    --Return to extra deck and summon another
    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.rtdcon)
    e4:SetTarget(s.rtdtg)
    e4:SetOperation(s.rtdop)
    c:RegisterEffect(e4)
end

function s.matfilter(c,scard,sumtype,tp)
    return c:IsAttackAbove(2300)
end

function s.cointg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,1)
end
function s.coinop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    s.arcanareg(c,Arcana.TossCoin(c,tp))
end
function s.arcanareg(c,coin)
    if coin==COIN_HEADS then
        --Return all graveyard cards and both players draw one
        local e1=Effect.CreateEffect(c)
        e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
        e1:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
        e1:SetRange(LOCATION_MZONE)
        e1:SetTarget(s.tdtg)
        e1:SetOperation(s.tdop)
        c:RegisterEffect(e1)
    elseif coin==COIN_TAILS then
        --Set attack to 2300
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_SET_ATTACK)
        e2:SetValue(2300)
        c:RegisterEffect(e2)
    end
    Arcana.RegisterCoinResult(c,coin)
end
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
    return Arcana.GetCoinResult(e:GetHandler())==COIN_HEADS
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local g=Duel.GetFieldGroup(tp,LOCATION_GRAVE,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,1)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetFieldGroup(tp,LOCATION_GRAVE,LOCATION_GRAVE)
    if #g>0 then
        Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        Duel.Draw(tp,1,REASON_EFFECT)
        Duel.Draw(1-tp,1,REASON_EFFECT)
    end
end
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return Arcana.GetCoinResult(e:GetHandler())==COIN_TAILS
end
function s.rtdcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==tp
end
function s.rtdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end
function s.spfilter(c,e,tp)
    return c:IsCode(62892347,124131050) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rtdop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end