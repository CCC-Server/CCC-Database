--Volcanic Search & Recycle
local s,id=GetID()
function s.initial_effect(c)
    -- 이 카드는 브레이즈 캐논 카드와 관련됨
    s.listed_names={69537999}
    s.listed_series={SET_VOLCANIC}

    --① 혹은 ② 중 1턴에 1번만 사용 가능
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --② 묘지 제외 후 리사이클 + 드로우
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.tdtg)
    e2:SetOperation(s.tdop)
    c:RegisterEffect(e2)
end
s.listed_series={SET_VOLCANIC,SET_BLAZE_ACCELERATOR}
s.listed_names={id}
--① 덱에서 "볼캐닉" 몬스터 1장과 "브레이즈 캐논" 카드 1장 서치
function s.thfilter1(c)
    return c:IsSetCard(SET_VOLCANIC) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thfilter2(c)
    return c:IsSetCard(SET_BLAZE_ACCELERATOR) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
            and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g1=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
    if #g1==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g2=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
    if #g2==0 then return end
    g1:Merge(g2)
    Duel.SendtoHand(g1,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g1)
end

--② 묘지 제외 → "볼캐닉" 또는 "브레이즈 캐논" 카드 3장 되돌리고 드로우
function s.tdfilter(c)
    return (c:IsSetCard(SET_VOLCANIC) or c:IsSetCard(SET_BLAZE_ACCELERATOR)) and c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.tdfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    if chk==0 then return g:GetClassCount(Card.GetCode)>=3 and Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_GRAVE+LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.tdfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    if #g<3 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local tg=g:Select(tp,3,3,nil)
    if #tg>0 then
        Duel.SendtoDeck(tg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
        local ct=tg:FilterCount(Card.IsLocation,nil,LOCATION_DECK)
        if ct>0 then Duel.ShuffleDeck(tp) end
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
