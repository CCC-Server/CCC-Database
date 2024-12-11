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
    if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local b1=Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
    local b2=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=7
    if not (b1 or b2) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
    local sel=0
    if b1 and b2 then
        sel=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
    elseif b1 then
        sel=Duel.SelectOption(tp,aux.Stringid(id,0))
    else
        sel=Duel.SelectOption(tp,aux.Stringid(id,1))+1
    end
    if sel==0 then
        -- 자신의 패 / 필드에서 카드를 1장 묘지로 보내고, 자신은 1장 드로우한다.
        if Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,e:GetHandler())
            and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
            local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,e:GetHandler())
            if Duel.SendtoGrave(g,REASON_EFFECT)~=0 and Duel.Draw(tp,1,REASON_EFFECT)~=0
                and Duel.IsExistingMatchingCard(function(c) return c:IsCode(124131244) and c:IsFaceup() end,tp,LOCATION_FZONE,0,1,nil) then
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
    elseif sel==1 then
        -- 자신의 덱 위에서 카드를 7장 넘긴다. 그 중에서 "앙크의 석판" 또는 그 카드명이 쓰여진 일반 마법 카드 1장을 자신 필드에 세트할 수 있다.
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
