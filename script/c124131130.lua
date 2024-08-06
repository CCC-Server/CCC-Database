--The Tower of Challenger
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    --pierce
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_PIERCE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.target)
    e2:SetValue(DOUBLE_DAMAGE)
    c:RegisterEffect(e2)
end

function s.thfilter(c)
    return c:IsCode(37364101) and c:IsAbleToHand()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    --Search 1 "Stoic Challenge"
    local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:Select(tp,1,1,nil)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

function s.filter(c)
    return c:GetEquipCount()>0 and c:GetEquipGroup():IsExists(Card.IsCode,1,nil,37364101)
end

function s.target(e,c)
    return s.filter(c)
end