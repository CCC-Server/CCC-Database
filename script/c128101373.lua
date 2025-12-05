--Aero Maneuver - Bell Draft
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50      -- "Fight Call"

function s.initial_effect(c)
    -- 카드군 표기용
    s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

    --------------------------------
    -- 글로벌: 이번 턴에 필드에서 패로 되돌아간 카드 수 카운트
    --------------------------------
    if not s.global_check then
        s.global_check=true
        s[0]=0
        -- 필드→패로 이동 감지
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_TO_HAND)
        ge1:SetOperation(s.regop)
        Duel.RegisterEffect(ge1,0)

        -- 턴 시작 시 리셋
        local ge2=Effect.CreateEffect(c)
        ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
        ge2:SetOperation(s.resetop)
        Duel.RegisterEffect(ge2,0)
    end

    --------------------------------
    -- (1) 이번 턴에 필드에서 패로 되돌아간 카드가 있으면,
    --     패 / 묘지에서 특수 소환 (프리 체인)
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e1:SetCountLimit(1,id) -- (1) 1턴 1번
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)

    --------------------------------
    -- (2) 특수 소환 성공시:
    --     덱에서 레벨 9 WIND 1장 서치 → (선택) 패에서 L6 이하 "Aero Maneuver" 특소
    --     이후 WIND 이외 특수 소환 불가
    --------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1}) -- (2) 1턴 1번
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    --------------------------------
    -- (3) 자신을 패로 되돌리고,
    --     묘지의 "Fight Call" 속공 마법 1장 세트
    --     이번 턴에 필드에서 패로 되돌아간 카드가 3장 이상이면
    --     세트한 카드는 세트한 턴에도 발동 가능
    --------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_LEAVE_GRAVE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,2}) -- (3) 1턴 1번
    e3:SetCost(s.setcost)
    e3:SetTarget(s.settg)
    e3:SetOperation(s.setop)
    c:RegisterEffect(e3)
end

--------------------------------
-- 글로벌 카운터 처리
--------------------------------
-- 필드에서 패로 되돌아간 카드 수 카운트
function s.regop(e,tp,eg,ep,ev,re,r,rp)
    local ct=eg:FilterCount(function(c) return c:IsPreviousLocation(LOCATION_ONFIELD) end,nil)
    if ct>0 then
        s[0]=(s[0] or 0)+ct
    end
end
-- 턴 시작 시 리셋
function s.resetop(e,tp,eg,ep,ev,re,r,rp)
    s[0]=0
end

--------------------------------
-- (1) 패 / 묘지 특수 소환
--------------------------------
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
    -- 이번 턴에 필드에서 패로 되돌아간 카드가 1장 이상
    return (s[0] or 0)>0
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

--------------------------------
-- (2) 서치 / 특소 관련
--------------------------------
-- 덱에서 서치할 레벨 9 WIND 몬스터
function s.lv9filter(c)
    return c:IsLevel(9) and c:IsAttribute(ATTRIBUTE_WIND)
        and c:IsMonster() and c:IsAbleToHand()
end
-- 패에서 특소할 L6 이하 "Aero Maneuver" 몬스터
function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_AEROMANEUVER) and c:IsLevelBelow(6)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.lv9filter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    -- 레벨 9 WIND 몬스터 1장 서치
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.lv9filter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,g)
        end
    end

    -- 그 후, (선택) 패에서 L6 이하 "Aero Maneuver" 몬스터 1장 특소
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
        and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
        if #sg>0 then
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
    end

    -- 이후 WIND 이외 특수 소환 불가
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetDescription(aux.Stringid(id,4))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit_wind)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

-- WIND 이외 특소 봉인
function s.splimit_wind(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsAttribute(ATTRIBUTE_WIND)
end

--------------------------------
-- (3) 코스트 & 세트
--------------------------------
-- 코스트: 이 카드를 패로 되돌림
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHandAsCost() end
    Duel.SendtoHand(c,nil,REASON_COST)
end

-- 세트할 "Fight Call" 속공 마법
function s.setfilter(c)
    return c:IsSetCard(SET_FIGHTCALL)
        and c:IsType(TYPE_SPELL) and c:IsType(TYPE_QUICKPLAY)
        and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),
        tp,LOCATION_GRAVE,0,1,1,nil)
    local tc=g:GetFirst()
    if not tc then return end
    if Duel.SSet(tp,tc)>0 then
        -- 이번 턴에 필드에서 패로 되돌아간 카드가 3장 이상이면,
        -- 세트한 턴에도 발동 가능
        if (s[0] or 0)>=3 then
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
            e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
        end
    end
end
