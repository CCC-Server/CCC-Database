-- 환홍허신 카누스
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 덱 탑 1장 덤핑 후 필드의 몬스터 2장까지 파괴
    -- 텍스트에 ①번 효과의 턴 제약이 없으므로 HOPT(1턴에 1번)를 적용하지 않습니다.
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DECKDES+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    -- ②: 제외되거나 효과로 묘지에 보내졌을 경우 (HOPT 적용)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1}) -- ②의 효과는 1턴에 1번
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_REMOVE)
    e3:SetCondition(s.setcon_rm)
    c:RegisterEffect(e3)
end

-- "환홍" 카드군 코드
s.set_phanred=0xfa8

-- [① 파괴 타겟] 몬스터 최대 2장 지정
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) end
    -- 발동 조건: 덱이 1장 이상 있어야 하고, 필드에 몬스터가 있어야 함
    if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,1)
        and Duel.IsExistingTarget(nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    -- 1장에서 2장까지 선택
    local g=Duel.SelectTarget(tp,nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,2,nil)
    Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

-- [① 파괴 효과 처리] 덱 탑 덤핑 후 파괴
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    -- 1. 자신의 덱 맨 위의 카드를 묘지로 보내고
    if Duel.DiscardDeck(tp,1,REASON_EFFECT)>0 then
        local tg=Duel.GetTargetCards(e)
        -- 2. 그 몬스터를 파괴한다. (대상이 필드에 남아있는지 확인)
        if #tg>0 then
            Duel.Destroy(tg,REASON_EFFECT)
        end
    end
end

-- [② 조건] 효과로 묘지행
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

-- [② 조건] 제외됨
function s.setcon_rm(e,tp,eg,ep,ev,re,r,rp)
    return true
end

-- [② 덱 넘기기 타겟] 덱이 최소 6장은 있어야 발동 가능
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=6 end
end

-- [② 환홍 함정 필터]
function s.setfilter(c)
    return c:IsSetCard(s.set_phanred) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

-- [② 덱 넘기기 효과 처리]
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    -- 덱 장수 재확인
    if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<6 then return end
    
    Duel.ConfirmDecktop(tp,6)
    local g=Duel.GetDecktopGroup(tp,6)
    if #g>0 then
        Duel.DisableShuffleCheck()
        local tg=g:Filter(s.setfilter,nil)
        
        -- 그 중에 "환홍" 함정 카드가 있다면 세트
        if #tg>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            -- 텍스트가 "세트할 수 있다"가 아니라 "세트한다"이므로 필수로 1장 선택
            local sg=tg:Select(tp,1,1,nil)
            local tc=sg:GetFirst()
            if tc and Duel.SSet(tp,tc)>0 then
                -- 이 효과로 세트한 카드는 당일 발동 가능 (스트링 2번 사용 추천)
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetDescription(aux.Stringid(id,2))
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
                e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
                e1:SetReset(RESET_EVENT|RESETS_STANDARD)
                tc:RegisterEffect(e1)
            end
            -- 세트한 카드를 그룹에서 제외 (덱으로 돌아가지 않도록)
            g:Sub(sg)
        end
        
        -- 남은 카드는 덱으로 되돌린다 (보통 셔플로 처리)
        if #g>0 then
            Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end