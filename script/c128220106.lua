--F로그라이크 러스트 인 피스 타운
local s,id=GetID()
function c128220106.initial_effect(c)
		--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Activate "Runick" Quick-Play Spells from your hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_HAND,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xc25))
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_TO_HAND)
    e3:SetRange(LOCATION_FZONE) 
    e3:SetCondition(s.condition)
    e3:SetTarget(s.target)
    e3:SetOperation(s.operation)
    c:RegisterEffect(e3)
end
function s.condition(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() ~= PHASE_DRAW 
        and eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_DECK)
end
function s.filter(c)
    return c:IsSetCard(0xc25)
        and (c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED))
        and c:IsAbleToDeck()
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkff)
    if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g = Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,3,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,g:GetCount(),0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.operation(e, tp, eg, ep, ev, re, r, rp)
    -- 1. 대상 카드 가져오기
    local tg = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
    local g = tg:Filter(Card.IsRelateToEffect, nil, e)
    if #g == 0 then return end
    -- 2. 좋아하는 순서대로 덱 아래로 되돌리기
    -- 보낼 카드의 총 수를 미리 저장합니다.
    local initial_count = #g
    local deck_count = 0
    for i = 1, initial_count do
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            -- 덱 아래(SEQ_DECKBOTTOM)로 보냄
            if Duel.SendtoDeck(sg, nil, SEQ_DECKBOTTOM, REASON_EFFECT) > 0 then
                deck_count = deck_count + 1
            end
            g:RemoveCard(sg:GetFirst())
        end
    end
    -- 덱으로 실제로 돌아간 카드가 있다면 (보통 엑스트라 덱 카드는 카운트에서 제외될 수 있음)
    if deck_count > 0 then
        -- 덱 셔플을 하지 않아야 덱 아래에 그대로 남습니다.
        -- Duel.SendtoDeck은 기본적으로 셔플을 하지 않지만, 명시적으로 확인.
        -- 3. 되돌린 수만큼 덱 위에서 넘기기
        Duel.ConfirmDecktop(tp, deck_count)
        local dg = Duel.GetDecktopGroup(tp, deck_count)
        if #dg > 0 then
            -- "F로그라이크" 카드 필터링 (0x123을 실제 번호로 수정하세요)
            local hg = dg:Filter(Card.IsSetCard, nil, 0xc25)
            local res = false
            if #hg > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
                Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
                local sc = hg:Select(tp, 1, 1, nil):GetFirst()
                if sc then
                    Duel.SendtoHand(sc, nil, REASON_EFFECT)
                    Duel.ConfirmCards(1-tp, sc)
                    dg:RemoveCard(sc)
                    res = true
                end
            end
            -- 4. 남은 카드는 덱 맨 아래로 되돌리기
            -- 패에 넣었을 경우 dg는 (deck_count - 1)장이 됩니다.
            if #dg > 0 then
                -- 유저가 순서를 정하도록 유도 (원하지 않으면 생략 가능)
                Duel.SortDecktop(tp, tp, #dg)
                for i = 1, #dg do
                    local tc = Duel.GetDecktopGroup(tp, 1):GetFirst()
                    Duel.MoveSequence(tc, SEQ_DECKBOTTOM)
                end
            end
            -- 카드를 넘겼음을 알리는 이펙트 (선택 사항)
            if res then Duel.ShuffleHand(tp) end
        end
    end
end