--비르투스 프리마 돈나
local s,id=GetID()
function c128220188.initial_effect(c)
Synchro.AddProcedure(c, nil, 1, 99, Synchro.NonTuner(nil), 1, 99)
    c:EnableReviveLimit()
    
    -- ①: 스탠바이 페이즈에 자신이 카드의 효과를 발동했을 경우에 발동할 수 있다. 묘지에서 "비르투스" 몬스터 1장을 특수 소환한다.
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- ②: 이 카드는 메인 페이즈 동안에는 카드의 효과로 파괴되지 않는다.
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(function() return Duel.IsMainPhase() end)
    e2:SetValue(function(e,te) return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated() end)
    c:RegisterEffect(e2)
    
    -- ③: 배틀 페이즈에 "비르투스" 몬스터의 효과가 발동했을 때에 발동할 수 있다(데미지 스텝에도 발동 가능). 필드의 카드 1장을 파괴한다.
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.descon)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)
    -- ④: 스탠바이 페이즈 / 메인 페이즈 / 배틀 페이즈에 전부 카드의 효과를 발동한 턴의 엔드 페이즈에 발동할 수 있다. 상대에게 1500 데미지를 준다.
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_DAMAGE)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_PHASE + PHASE_END)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1, {id, 1})
    e4:SetCondition(s.epcon)
    e4:SetTarget(s.damtg)
    e4:SetOperation(s.damop)
    c:RegisterEffect(e4)
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

-- 카드군 번호 "비르투스" (0xc29) 체크 함수
function s.is_virtus(c)
    return c:IsSetCard(0xc29)
end

-- ①번 효과 관련 함수
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() == PHASE_STANDBY and rp == tp
end
function s.spfilter(c, e, tp)
    return s.is_virtus(c) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- ②번 효과 관련 함수
function s.indcon(e)
    local ph = Duel.GetCurrentPhase()
    return ph >= PHASE_MAIN1 and ph <= PHASE_MAIN2
end

-- ③번 효과 관련 함수
function s.descon(e, tp, eg, ep, ev, re, r, rp)
    -- 배틀 페이즈(데미지 스텝 포함)인지 확인
    local ph = Duel.GetCurrentPhase()
    if ph < PHASE_BATTLE_START or ph > PHASE_BATTLE then return false end
    
    -- 발동한 효과의 소스(re)가 몬스터 카드인지 확인
    if not re:IsActiveType(TYPE_MONSTER) then return false end
    
    -- 발동한 몬스터가 "이 카드 이외의 카드"이며, "비르투스" 카드군인지 확인
    local rc = re:GetHandler()
    return rc ~= e:GetHandler() and rc:IsSetCard(0xc29)
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
    local g = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectMatchingCard(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
    if #g > 0 then
        Duel.HintSelection(g)
        Duel.Destroy(g, REASON_EFFECT)
    end
end

-- ④번 효과 관련 함수
function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    return s.flag_sp[tp] and s.flag_mp[tp] and s.flag_bp[tp]
end
function s.damtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetTargetPlayer(1-tp)
    Duel.SetTargetParam(1500)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1-tp, 1500)
end
function s.damop(e, tp, eg, ep, ev, re, r, rp)
    local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
    Duel.Damage(p, d, REASON_EFFECT)
end
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