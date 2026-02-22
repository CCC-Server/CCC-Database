-- 환홍허신 안틸라
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 덱 탑 1장 덤핑 후 묘지/제외 상태의 카드를 정확히 2장 덱 바운스, 그 후 1장 드로우
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TODECK+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
    e1:SetTarget(s.tdtg)
    e1:SetOperation(s.tdop)
    c:RegisterEffect(e1)

    -- ②: 제외되거나 효과로 묘지에 보내졌을 경우
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_REMOVE)
    e3:SetCondition(s.setcon_rm)
    c:RegisterEffect(e3)
end

-- "환홍" 카드군 코드 (0xfa8)
s.set_phanred=0xfa8

-- [① 덱 바운스 타겟: 정확히 2장 지정]
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) and chkc:IsAbleToDeck() end
    if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,1) and Duel.IsPlayerCanDraw(tp,1)
        and Duel.IsExistingTarget(Card.IsAbleToDeck,tp,LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE|LOCATION_REMOVED,2,nil) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE|LOCATION_REMOVED,2,2,nil)
    Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,2,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,1,tp,1)
end

-- [① 덱 바운스 효과 처리: 탐욕의 항아리 로직 적용] 
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    -- 1. 자신의 덱 맨 위의 카드를 묘지로 보내고
    if Duel.DiscardDeck(tp,1,REASON_EFFECT)>0 then
        -- 타겟팅된 카드를 가져와서 대상 지정이 유지되고 있는지(2장) 확인
        local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
        if not tg or tg:FilterCount(Card.IsRelateToEffect,nil,e)~=2 then return end
        
        -- 2. 탐욕의 항아리처럼 일단 덱 맨 위로 보냅니다.
        Duel.SendtoDeck(tg,nil,SEQ_DECKTOP,REASON_EFFECT)
        local og=Duel.GetOperatedGroup()
        
        -- 메인 덱으로 돌아간 카드가 있다면 셔플을 진행합니다.
        if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
            -- 자신 덱으로 간 카드가 있으면 자신 덱 셔플
            if og:IsExists(Card.IsControler,1,nil,tp) then Duel.ShuffleDeck(tp) end
            -- 상대 덱으로 간 카드가 있으면 상대 덱 셔플
            if og:IsExists(Card.IsControler,1,nil,1-tp) then Duel.ShuffleDeck(1-tp) end
        end
        
        -- 덱/엑스트라 덱으로 돌아간 카드가 정확히 2장인지 체크합니다.
        local ct=og:FilterCount(Card.IsLocation,nil,LOCATION_DECK|LOCATION_EXTRA)
        if ct==2 then
            -- 3. "그 후", 자신은 1장 드로우한다.
            Duel.BreakEffect()
            Duel.Draw(tp,1,REASON_EFFECT)
        end
    end
end

-- [② 조건]
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

function s.setcon_rm(e,tp,eg,ep,ev,re,r,rp)
    return true
end

-- [② 덱 넘기기 타겟]
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=6 end
end

-- [② 환홍 함정 필터]
function s.setfilter(c)
    return c:IsSetCard(s.set_phanred) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

-- [② 덱 넘기기 효과 처리]
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<6 then return end
    
    Duel.ConfirmDecktop(tp,6)
    local g=Duel.GetDecktopGroup(tp,6)
    
    if #g>0 then
        Duel.DisableShuffleCheck()
        local tg=g:Filter(s.setfilter,nil)
        
        if #tg>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local tc=tg:Select(tp,1,1,nil):GetFirst()
            if tc and Duel.SSet(tp,tc)>0 then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetDescription(aux.Stringid(id,2))
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
                e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
                e1:SetReset(RESET_EVENT|RESETS_STANDARD)
                tc:RegisterEffect(e1)
            end
        end
        
        Duel.ShuffleDeck(tp)
    end
end