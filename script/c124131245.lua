--앙크의 퍼즐
local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DRAW+CATEGORY_TOHAND+CATEGORY_FUSION_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- Banish when sent to Graveyard
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.bantg)
    e2:SetOperation(s.banop)
    c:RegisterEffect(e2)
end
s.listed_names={124131244}
function s.thfilter(c)
    return c:ListsCode(124131244) and c:GetType()==TYPE_SPELL and c:IsAbleToHand() and not c:IsCode(id)
end
function s.fusfilter(c)
    return c:IsCanBeFusionMaterial() and c:IsAbleToGrave()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,e:GetHandler())
    local b2=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=7
    if chk==0 then return b1 or b2 end
    if not b1 and not b2 then return false end
    if not b1 then
        e:SetLabel(1)
    elseif not b2 then
        e:SetLabel(0)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
        e:SetLabel(Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1)))
    end
    if e:GetLabel()==0 then
        Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD)
        Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
    else
        Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,7,tp,LOCATION_DECK)
    end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if e:GetLabel()==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,e:GetHandler())
        if Duel.SendtoGrave(g,REASON_EFFECT)~=0 and Duel.Draw(tp,1,REASON_EFFECT)~=0 then
            if Duel.IsExistingMatchingCard(function(c) return c:IsCode(124131244) and c:IsFaceup() end,tp,LOCATION_FZONE,0,1,nil) then
                if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                    local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
                    if #sg>0 then
                        Duel.SendtoHand(sg,nil,REASON_EFFECT)
                        Duel.ConfirmCards(1-tp,sg)
                    end
                end
            end
        end
    elseif e:GetLabel()==1 then
        if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=7 then
            Duel.ConfirmDecktop(tp,7)
            local g=Duel.GetDecktopGroup(tp,7)
            if #g>0 then
                local sg=g:FilterSelect(tp,function(c) return c:IsCode(124131244) or (c:ListsCode(124131244) and c:GetType()==TYPE_SPELL) end,1,1,nil)
                if #sg>0 then
                    Duel.SSet(tp,sg:GetFirst())
                end
                Duel.ShuffleDeck(tp)
            end
        end
    end
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