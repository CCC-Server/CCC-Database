--앙크의 천칭
local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- Banish when sent to Graveyard
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.bantg)
    e2:SetOperation(s.banop)
    c:RegisterEffect(e2)
end
s.listed_names={124131244,CARD_POLYMERIZATION}

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local deckCount = Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
    local handFieldCount = Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
    if chk==0 then return handFieldCount or deckCount >= 7 end
    if not handFieldCount and deckCount < 7 then
        return false
    end
    local op=0
    if not handFieldCount then
        op=1
    elseif deckCount < 7 then
        op=0
    else
        op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
    end
    e:SetLabel(op)
    if op==0 then
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_REMOVED)
    else
        Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,7,tp,LOCATION_DECK)
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local op = e:GetLabel()
    if op==0 then
        if Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
            local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
            if Duel.SendtoGrave(g,REASON_EFFECT)~=0 and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_REMOVED,0,1,nil) then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_REMOVED,0,1,1,nil)
                if #sg>0 then
                    Duel.SendtoHand(sg,nil,REASON_EFFECT)
                    Duel.ConfirmCards(1-tp,sg)
                end
            end
        end
        if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,124131244),tp,LOCATION_FZONE,0,1,nil) then
            if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_DECK,0,1,1,nil,CARD_POLYMERIZATION)
                if #sg>0 then
                    Duel.SendtoHand(sg,nil,REASON_EFFECT)
                    Duel.ConfirmCards(1-tp,sg)
                end
            end
        end
    elseif op==1 then
        if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=7 then
            Duel.ConfirmDecktop(tp,7)
            local g=Duel.GetDecktopGroup(tp,7)
            if #g>0 then
                local sg=g:FilterSelect(tp,function(c) return c:IsCode(124131244) or (c:ListsCode(124131244) and c:IsType(TYPE_SPELL)) end,1,1,nil)
                if #sg>0 then
                    Duel.SSet(tp,sg:GetFirst())
                end
                Duel.ShuffleDeck(tp)
            end
        end
    end
end

function s.thfilter(c)
    return c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
    end
end