--JJ-오라오라오라오라
local s,id=GetID()
function c128220134.initial_effect(c)
local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0xc26)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    -- chk == 0일 때는 가능 여부만 반환하고 함수를 종료해야 합니다.
    if chk==0 then return Duel.IsExistingTarget(s.filter, tp, LOCATION_MZONE, 0, 1, nil) end
    
    -- chk == 1일 때(실제 발동 시) 대상을 선택합니다.
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    local g = Duel.SelectTarget(tp, s.filter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    
    -- "JJ-쿠죠 죠타로"일 경우 파괴 카테고리를 추가 (선택 사항이지만 권장)
    if g:GetFirst():IsCode(128220120) then
        e:SetCategory(CATEGORY_DESTROY)
    else
        e:SetCategory(0)
    end
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() then
        -- 1. 1번의 배틀 페이즈 중에 4회 공격 가능
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EXTRA_ATTACK)
        e1:SetValue(3) -- 기본 1회 + 추가 3회 = 총 4회
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        
        -- 2. 상대가 받는 모든 데미지 절반 (잔존 효과)
        local e2 = Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_CHANGE_DAMAGE)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e2:SetTargetRange(0, 1)
        e2:SetValue(s.damval)
        e2:SetReset(RESET_PHASE + PHASE_END)
        Duel.RegisterEffect(e2, tp)
        
        -- 3. "JJ-쿠죠 죠타로"일 경우 추가 파괴
        if tc:IsCode(128220120) and Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_MZONE, 1, nil) then
            if Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then 
                Duel.BreakEffect()
                Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
                local dg = Duel.SelectMatchingCard(tp, aux.TRUE, tp, 0, LOCATION_MZONE, 1, 1, nil)
                if #dg > 0 then
                    Duel.Destroy(dg, REASON_EFFECT)
                end
            end
        end
    end
end

-- 데미지 절반 계산 함수
function s.damval(e, re, val, r, rp, rc)
    return math.floor(val / 2)
end