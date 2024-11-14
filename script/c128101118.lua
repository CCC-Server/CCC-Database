--scripted by pyrQ
local s,id=GetID()
function s.initial_effect(c)
         c:EnableReviveLimit()
    -- Special Summon from Deck (1번 효과)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Negate special summon (2번 효과)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_SPSUMMON)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.discon)
    e2:SetCost(s.discost)
    e2:SetTarget(s.distg)
    e2:SetOperation(s.disop)
    c:RegisterEffect(e2)
end

s.listed_series={0xc41}

-- Special Summon from Deck (1번 효과)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0xc41) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    if #tg>0 then
        Duel.SpecialSummon(tg,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Negate special summon (2번 효과)
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    return tp~=ep and Duel.GetCurrentChain()==0
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToHandAsCost() end
    Duel.SendtoHand(e:GetHandler(),nil,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,#eg,0,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,#eg,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateSummon(eg)
    Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
end
