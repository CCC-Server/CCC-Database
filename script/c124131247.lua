local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE+CATEGORY_CONTROL+CATEGORY_TODECK)
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

s.listed_names={124131244}

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_DECK,0,1,nil) and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
    local b1=Duel.IsExistingMatchingCard(aux.NecroValleyFilter(Card.IsAbleToRemove),tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil)
    local b2=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=7
    local op=0
    if not b1 and not b2 then
        return false
    elseif not b1 then
        op=1
    elseif not b2 then
        op=0
    else
        op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
    end
    e:SetLabel(op)
    if op==0 then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
    elseif op==1 then
        Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,7,tp,LOCATION_DECK)
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if e:GetLabel()==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsAbleToRemove),tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
        if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=0 
            and Duel.IsExistingMatchingCard(function(c) return c:IsCode(124131244) and c:IsFaceup() end,tp,LOCATION_FZONE,0,1,nil) then
            local tg=Duel.GetMatchingGroup(s.filter2,tp,0,LOCATION_MZONE,nil)
            if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
                local sg=tg:Select(tp,1,1,nil)
                if #sg>0 then
                    Duel.GetControl(sg,tp,PHASE_END,1)
                end
            end
        end
    else
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

function s.filter2(c)
    return c:IsAttackBelow(2000) and c:IsControlerCanBeChanged()
end