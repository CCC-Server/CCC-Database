-- 주술회전 카드 스크립트
local s,id=GetID()
function s.initial_effect(c)
    -- Activate effect (Continuous Spell)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- ①: 의식 몬스터 이외의 몬스터가 앞면 표시로 일반 소환 / 특수 소환되었을 경우
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- Clone the effect for special summon
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    -- ②: 자신의 묘지의 "주술회전" 카드 3장을 대상으로 하여 덱으로 되돌리고 셔플
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(1,id))
    e4:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCountLimit(1,{id,1}) -- Different count limit to distinguish from effect 1
    e4:SetTarget(s.tdtg)
    e4:SetOperation(s.tdop)
    c:RegisterEffect(e4)
end

s.listed_series={0xc41}

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(c) return not c:IsType(TYPE_RITUAL) and c:IsFaceup() end, 1, nil)
end

-- Special summon target filter
function s.spfilter(c,e,tp)
    return c:IsSetCard(0xc41) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Special summon target selection
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,tp,0)
end

-- Special summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Target filter for card return
function s.cfilter(c)
    return c:IsSetCard(0xc41) and c:IsAbleToDeck() and (c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED))
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1) and Duel.IsExistingTarget(s.cfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(tp,s.cfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,tp,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    local tg=Duel.GetTargetCards(e)
    if #tg==0 or Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
    local g=Duel.GetOperatedGroup()
    if not g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then return end
    if g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then Duel.ShuffleDeck(tp) end
    Duel.BreakEffect()
    Duel.Draw(tp,1,REASON_EFFECT)
end
