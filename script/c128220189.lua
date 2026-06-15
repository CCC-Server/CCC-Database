--비르투스 마에스트로
local s,id=GetID()
function s.initial_effect(c) 
    Synchro.AddProcedure(c, nil, 1, 99, Synchro.NonTuner(nil), 1, 99)
    c:EnableReviveLimit()
  local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_COUNTER)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.ctcon)
    e1:SetTarget(s.cttg)
    e1:SetOperation(s.ctop)
    c:RegisterEffect(e1)

    -- 2: 메인 페이즈 효과
    local e2 = e1:Clone()
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCondition(s.ctmcon)
    c:RegisterEffect(e2)

    -- 3: 배틀 페이즈 효과
    local e3 = e1:Clone()
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCondition(s.ctbcon)
    c:RegisterEffect(e3)

    -- 4: 엔드 페이즈 효과
    local e4 = e1:Clone()
    e4:SetDescription(aux.Stringid(id, 3))
    e4:SetCondition(s.ctecon)
    c:RegisterEffect(e4)
    
    -- ②: 상대 몬스터 효과 발동 무효화 (카운터 2개 제거)
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_CHAINING)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.discon)
    e5:SetCost(s.discost)
    e5:SetTarget(s.distg)
    e5:SetOperation(s.disop)
    c:RegisterEffect(e5)
    
    -- ③: 덱에서 "비르투스" 몬스터 특수 소환 (카운터 1개 제거, 1턴에 1번)
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 2))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetCost(s.spcost)
    e6:SetTarget(s.sptg)
    e6:SetOperation(s.spop)
    c:RegisterEffect(e6)
end

-- 카드군 번호 및 카운터 상수 정의
s.setname_virtus = 0xc29
local COUNTER_MUSIC = 0x1c29 -- 악장 카운터

---------------------------------------------------------------------------------
-- ①번 효과 관련 함수 (카운터 놓기)

function s.ctcon(e, tp, eg, ep, ev, re, r, rp)
       return Duel.IsPhase(PHASE_STANDBY) and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
function s.ctmcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase() and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
function s.ctbcon(e, tp, eg, ep, ev, re, r, rp)
       return Duel.IsBattlePhase() and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
function s.ctecon(e, tp, eg, ep, ev, re, r, rp)
       return Duel.IsPhase(PHASE_END) and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
-- 카운터 적치 타겟
function s.cttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanAddCounter(COUNTER_MUSIC, 1) end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, e:GetHandler(), 1, 0, COUNTER_MUSIC)
end

-- 카운터 적치 실행
function s.ctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:AddCounter(COUNTER_MUSIC, 1)
    end
end
---------------------------------------------------------------------------------
-- ②번 효과 관련 함수 (상대 몬스터 무효화)

function s.discon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end

function s.discost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, COUNTER_MUSIC, 2, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, COUNTER_MUSIC, 2, REASON_COST)
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end

---------------------------------------------------------------------------------
-- ③번 효과 관련 함수 (덱 특수 소환)

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, COUNTER_MUSIC, 1, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, COUNTER_MUSIC, 1, REASON_COST)
end

function s.spfilter(c, e, tp)
    return c:IsSetCard(s.setname_virtus) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end