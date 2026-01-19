--어둠의 일족의 투기 - 괴염왕 대차옥
local s,id=GetID()
function c128220150.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.descon)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id)
    e2:SetTarget(s.tdtg)
    e2:SetOperation(s.tdop)
    c:RegisterEffect(e2)
end
s.esidisi = 128220142
function s.descon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, s.esidisi), tp, LOCATION_MZONE, 0, 1, nil)
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_SZONE, nil, TYPE_SPELL + TYPE_TRAP)
    if chk == 0 then return #g > 0 end
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_SZONE, nil, TYPE_SPELL + TYPE_TRAP)
    if #g > 0 then
        Duel.Destroy(g, REASON_EFFECT)
    end
end
function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and chkc ~= e:GetHandler() end
    if chk == 0 then return e:GetHandler():IsAbleToDeck()
        and Duel.IsExistingTarget(Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 1, e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectTarget(tp, Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 1, 1, e:GetHandler())
    g:AddCard(e:GetHandler())
    Duel.SetOperationInfo(0, CATEGORY_TODECK, g, 2, 0, 0)
end
function s.tdop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
        local g = Group.FromCards(c, tc)
        Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
    end
end