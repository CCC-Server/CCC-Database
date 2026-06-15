--비르투스-피날레
local s,id=GetID()
function c128220193.initial_effect(c)
-- ① 메인 발동 효과
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(TIMING_END_PHASE)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- 글로벌 턴 플래그 감지
    if not s.global_check then
        s.global_check = true
        local ge1 = Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_CHAINING)
        ge1:SetOperation(s.chain_check_op)
        Duel.RegisterEffect(ge1, 0)
    end
end

s.counter_code = 0x1c29

function s.chain_check_op(e, tp, eg, ep, ev, re, r, rp)
    local phase = Duel.GetCurrentPhase()
    local p = rp
    
    if phase == PHASE_STANDBY then
        Duel.RegisterFlagEffect(p, id + PHASE_STANDBY, RESET_PHASE + PHASE_END, 0, 1)
    elseif phase == PHASE_MAIN1 or phase == PHASE_MAIN2 then
        Duel.RegisterFlagEffect(p, id + PHASE_MAIN1, RESET_PHASE + PHASE_END, 0, 1)
    elseif phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE then
        Duel.RegisterFlagEffect(p, id + PHASE_BATTLE, RESET_PHASE + PHASE_END, 0, 1)
    end
end

function s.condition(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_END
       and Duel.GetFlagEffect(tp, id + PHASE_STANDBY) > 0
       and Duel.GetFlagEffect(tp, id + PHASE_MAIN1) > 0
       and Duel.GetFlagEffect(tp, id + PHASE_BATTLE) > 0
end

-- 수량 선택을 위한 헬퍼 함수
function s.check_count(tp, max_c)
    local t = {}
    for i = 1, max_c do
        table.insert(t, i)
    end
    return t
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    -- 자신 필드의 총 카운터 수
    local max_count = Duel.GetCounter(tp, 1, 0, s.counter_code)
    -- 상대 필드의 제외 가능한 카드 수
    local opp_count = Duel.GetMatchingGroupCount(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, nil)
    
    if chk == 0 then 
        return max_count > 0 and opp_count > 0 and Duel.IsCanRemoveCounter(tp, 1, 0, s.counter_code, 1, REASON_COST)
    end
    
    -- 가용한 최대 수량 재조정
    if max_count > opp_count then max_count = opp_count end
    
    -- [안전 장치] 선택 가능한 숫자 배열 생성 (예: 1장부터 max_count장까지)
    local nums = s.check_count(tp, max_count)
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_LVRANK) -- 임시 메시지박스 호출
    local ct = Duel.AnnounceNumber(tp, table.unpack(nums))
    
    -- 선택한 수만큼 카운터 제거 후 라벨 저장
    Duel.RemoveCounter(tp, 1, 0, s.counter_code, ct, REASON_COST)
    e:SetLabel(ct)
    
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, ct, 1-tp, LOCATION_ONFIELD)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
    local ct = e:GetLabel()
    local g = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, nil)
    
    -- 효과 처리 시점에 상대 카드가 줄어들었을 가능성을 대비한 최적화
    if #g > 0 then
        local select_ct = math.min(ct, #g) -- 혹시 그새 상대 카드가 줄었다면 남은 만큼만 제외
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
        local sg = g:Select(tp, select_ct, select_ct, nil)
        if #sg > 0 then
            Duel.HintSelection(sg)
            Duel.Remove(sg, POS_FACEUP, REASON_EFFECT)
        end
    end
end