--JJ-죠스타 가의 전통적인 싸움법
local s,id=GetID()
function c128220133.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_IGNITION) 
    e2:SetRange(LOCATION_GRAVE)      
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)          
    e2:SetCost(s.cost)              
    e2:SetTarget(s.ttarget)           
    e2:SetOperation(s.operation)     
    c:RegisterEffect(e2)
end
function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0xc26) and c:IsAbleToRemove()
end
function s.opp_filter(c)
    return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return false end
    if chk == 0 then 
        return Duel.IsExistingTarget(s.filter, tp, LOCATION_MZONE, 0, 1, nil)
           and Duel.IsExistingTarget(s.opp_filter, tp, 0, LOCATION_MZONE, 1, nil) 
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g1 = Duel.SelectTarget(tp, s.filter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g2 = Duel.SelectTarget(tp, s.opp_filter, tp, 0, LOCATION_MZONE, 1, 1, nil)
    g1:Merge(g2)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g1, 2, 0, 0)
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetTargetCards(e)
    if g:GetCount() > 0 then
        if Duel.Remove(g, POS_FACEUP, REASON_EFFECT + REASON_TEMPORARY) ~= 0 then
            local og = Duel.GetOperatedGroup()
            local oc = og:GetFirst()
            while oc do
                local e1 = Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
                e1:SetCode(EVENT_PHASE + PHASE_END)
                e1:SetReset(RESET_PHASE + PHASE_END)
                e1:SetCountLimit(1)
                e1:SetLabelObject(oc)
                e1:SetCondition(s.retcon)
                e1:SetOperation(s.retop)
                Duel.RegisterEffect(e1, tp)
                oc = og:GetNext()
            end
        end
    end
end
function s.retcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetLabelObject():GetLocation() == LOCATION_REMOVED
end
function s.retop(e, tp, eg, ep, ev, re, r, rp)
    Duel.SendtoHand(e:GetLabelObject(), nil, REASON_EFFECT)
end
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(), POS_FACEUP, REASON_COST)
end
function s.thfilter(c)
    return c:IsSetCard(0xc26) and c:IsAbleToDeck() 
        and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.ttarget(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(tp) and s.thfilter(chkc) end
    if chk == 0 then 
        return Duel.IsPlayerCanDraw(tp, 1)
            and Duel.IsExistingTarget(s.thfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 3, e:GetHandler()) 
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectTarget(tp, s.thfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 3, 3, e:GetHandler())
    Duel.SetOperationInfo(0, CATEGORY_TODECK, g, 3, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end
function s.operation(e, tp, eg, ep, ev, re, r, rp)
    local tg = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect, nil, e)
    if #tg <= 0 then return end
    Duel.SendtoDeck(tg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
    local g = Duel.GetOperatedGroup()
    if g:IsExists(Card.IsLocation, 1, nil, LOCATION_DECK + LOCATION_EXTRA) then
        if g:IsExists(Card.IsLocation, 1, nil, LOCATION_DECK) then Duel.ShuffleDeck(tp) end
        Duel.BreakEffect()
        Duel.Draw(tp, 1, REASON_EFFECT)
    end
end