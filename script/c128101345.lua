local s,id=GetID()
function s.initial_effect(c)

    ---------------------------------------------------
    -- Xyz Summon
    ---------------------------------------------------
    Xyz.AddProcedure(c,nil,5,3)
    c:EnableReviveLimit()

    ---------------------------------------------------
    -- ① Special Summon Success → Mill 5 → Destroy
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.tg1)
    e1:SetOperation(s.op1)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- ② Detach → Declare → Reveal → Indestructible → Optional GY to Hand
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_ANNOUNCE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.cost2)
    e2:SetTarget(s.tg2)
    e2:SetOperation(s.op2)
    c:RegisterEffect(e2)
end


---------------------------------------------------
-- ① Mill 5 → Destroy Stellaron count
---------------------------------------------------
function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end

    Duel.ConfirmDecktop(tp,5)
    local g=Duel.GetDecktopGroup(tp,5)
    local ct=g:FilterCount(Card.IsSetCard,nil,0xc47)

    if ct>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local dg=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,ct,nil)
        if #dg>0 then Duel.Destroy(dg,REASON_EFFECT) end
    end
end


---------------------------------------------------
-- ② Cost
---------------------------------------------------
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
    c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

---------------------------------------------------
-- ② Declare target
---------------------------------------------------
local type_map={
    [0]=TYPE_MONSTER,
    [1]=TYPE_SPELL,
    [2]=TYPE_TRAP
}

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 end
    Duel.Hint(HINT_SELECTMSG,tp,569)
    local ann=Duel.AnnounceType(tp) -- 0/1/2
    e:SetLabel(ann)
end

---------------------------------------------------
-- ② Operation
---------------------------------------------------
function s.gyfilter(c)
    return c:IsSetCard(0xc47) and c:IsAbleToHand()
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ann=e:GetLabel()
    local t=type_map[ann]

    if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

    -- Reveal top card of opponent's Deck
    Duel.ConfirmDecktop(1-tp,1)
    local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
    if not tc then return end

    local match = tc:IsType(t)

    -- Indestructible this turn
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e2)

    -- If matched → add Stellaron Hunter from GY to hand
    if match then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end
