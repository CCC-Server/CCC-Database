-- 노드 아밀리아
local s,id=GetID()
function s.initial_effect(c)
    -- 엑시즈 소환 조건: 환상마족 레벨 3 몬스터 × 2
    c:EnableReviveLimit()
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_ILLUSION),3,2)

    -- ①: 같은 세로열의 상대 앞면 표시 몬스터의 공/수 1000 다운
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(0,LOCATION_MZONE)
    e1:SetTarget(s.atktg)
    e1:SetValue(-1000)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)

    -- ②: 다음 자신의 턴의 스탠바이 페이즈에 환상마족 특수 소환 (기동 효과)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    -- ③: 메인 몬스터 존 위치 교환. 그 후, 조건 만족 시 마/함 무효 (상대 턴 한정)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_DISABLE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetHintTiming(0,TIMING_MAIN_END+TIMINGS_CHECK_MONSTER_E)
    e4:SetCondition(s.swapcon)
    e4:SetCost(aux.bfgcost)
    e4:SetTarget(s.swaptg)
    e4:SetOperation(s.swapop)
    c:RegisterEffect(e4)
end

-- [① 타겟 지정] 이 카드와 같은 세로열인지 확인
function s.atktg(e,c)
    return e:GetHandler():GetColumnGroup():IsContains(c)
end

-- [② 발동 시 타겟]
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- [② 발동 시 효과 처리] 지연 효과 등록
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e1:SetCountLimit(1)
    e1:SetLabel(Duel.GetTurnCount())
    e1:SetCondition(s.spcon_delay)
    e1:SetOperation(s.spop_delay)
    e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_SELF_TURN,1)
    Duel.RegisterEffect(e1,tp)
end

-- [② 지연 효과 조건] "자신의" 턴인가?
function s.spcon_delay(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsTurnPlayer(tp) and Duel.GetTurnCount()~=e:GetLabel()
end

function s.spfilter(c,e,tp)
    return c:IsRace(RACE_ILLUSION) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- [② 지연 효과 처리]
function s.spop_delay(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    if g:GetCount()>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- [③ 메인 몬스터 존 필터]
function s.mmzfilter(c)
    return c:GetSequence()<5
end

-- [③ 조건] 상대 턴 & 자신 메인 몬스터 존에 몬스터 2장 이상
function s.swapcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()~=tp and Duel.GetMatchingGroupCount(s.mmzfilter,tp,LOCATION_MZONE,0,nil)>=2
end

-- [③ 타겟 지정] 대상을 취하지 않음 ("고르고")
function s.swaptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetMatchingGroupCount(s.mmzfilter,tp,LOCATION_MZONE,0,nil)>=2 end
end

-- [③ 내 필드의 앞면 표시 환상마족 확인 필터]
function s.illfilter(c,tp)
    return c:IsRace(RACE_ILLUSION) and c:IsFaceup() and c:IsControler(tp)
end

-- [③ 무효화할 마/함 탐색 필터]
function s.negfilter(c,tp)
    return c:IsFaceup() and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsDisabled() 
        and c:GetColumnGroup():IsExists(s.illfilter,1,nil,tp)
end

-- [③ 효과 처리] 순차적 실행 (위치 교환 → 그 후 → 마함 무효)
function s.swapop(e,tp,eg,ep,ev,re,r,rp)
    -- 【Step 1】: 메인 몬스터 존에서 2장을 "고르고"
    local g=Duel.GetMatchingGroup(s.mmzfilter,tp,LOCATION_MZONE,0,nil)
    if g:GetCount()<2 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local sg=g:Select(tp,2,2,nil)
    if sg:GetCount()~=2 then return end
    
    local tc1=sg:GetFirst()
    local tc2=sg:GetNext()
    
    -- 【Step 2】: 그 2장의 위치를 "맞바꾼다"
    Duel.SwapSequence(tc1,tc2)
    
    -- 【Step 3 & 4】: 위치가 바뀐 뒤의 세로열을 안전하게 재검색
    local st_g = Duel.GetMatchingGroup(s.negfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,tp)
    if st_g:GetCount() == 0 then return end
    
    -- 【Step 5】: 앞면 표시 마/함 1장을 골라 무효로 "할 수 있다"
    if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        Duel.BreakEffect()
        
        -- ★★★ 여기가 원인이었습니다! HINTMSG_DISABLE을 안전한 HINTMSG_FACEUP으로 변경했습니다 ★★★
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
        
        local dg = st_g:Select(tp,1,1,nil)
        local dc = dg:GetFirst()
        
        if dc then
            Duel.HintSelection(dg)
            Duel.NegateRelatedChain(dc,RESET_TURN_SET)
            
            local c=e:GetHandler()
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            dc:RegisterEffect(e1)
            
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetValue(RESET_TURN_SET)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            dc:RegisterEffect(e2)
        end
    end
end