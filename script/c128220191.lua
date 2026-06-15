--비르투스-인터류드
local s,id=GetID()
function c128220191.initial_effect(c)
-- ①: 덱에서 "비르투스" 몬스터 1장을 패에 넣는다.
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- ③번 효과: 스탠바이/메인/배틀 페이즈에 전부 효과를 발동한 턴의 엔드 페이즈에 묘지에서 회수
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_PHASE + PHASE_END)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1, {id, 1})
    e2:SetCondition(s.epcon)
    e2:SetTarget(s.eptg)
    e2:SetOperation(s.epop)
    c:RegisterEffect(e2)

    -- ③번 효과의 조건을 체크하기 위한 글로벌 턴 플래그 감지 (듀얼 전체에 영향)
    if not s.global_check then
        s.global_check = true
        local ge1 = Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_CHAINING)
        ge1:SetOperation(s.chain_check_op)
        Duel.RegisterEffect(ge1, 0)
    end
end

-- "비르투스" 카드군 지정
s.listed_series={0xc29} 

-- ①번 효과 함수
function s.thfilter(c)
    return c:IsSetCard(0xc29) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
   local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- ==================== ③번 효과 및 플래그 체크 루틴 ====================
function s.chain_check_op(e, tp, eg, ep, ev, re, r, rp)
    -- 효과를 발동한 플레이어(자신)의 페이즈별 플래그를 누적 기록
    local phase = Duel.GetCurrentPhase()
    local p = rp -- 효과를 발동한 플레이어 기준 (만약 자신/상대 상관없이 유저 기준이라면 tp 사용 가능, 본 코드는 발동 유저 기준 기록)
    
    if phase == PHASE_STANDBY then
        Duel.RegisterFlagEffect(p, id + PHASE_STANDBY, RESET_PHASE + PHASE_END, 0, 1)
    elseif phase == PHASE_MAIN1 or phase == PHASE_MAIN2 then
        Duel.RegisterFlagEffect(p, id + PHASE_MAIN1, RESET_PHASE + PHASE_END, 0, 1)
    elseif phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE then
        Duel.RegisterFlagEffect(p, id + PHASE_BATTLE, RESET_PHASE + PHASE_END, 0, 1)
    end
end

function s.epcon(e, tp, eg, ep, ev, re, r, rp)
    -- 효과 발동 대상 플레이어(tp)가 오늘 턴 동안 세 페이즈 모두에서 효과를 발동했었는지 플래그 검사
    return Duel.GetFlagEffect(tp, id + PHASE_STANDBY) > 0
       and Duel.GetFlagEffect(tp, id + PHASE_MAIN1) > 0
       and Duel.GetFlagEffect(tp, id + PHASE_BATTLE) > 0
end

function s.eptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, c, 1, 0, 0)
end

function s.epop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c, nil, REASON_EFFECT)
        Duel.ConfirmCards(1-tp, c)
    end
end

