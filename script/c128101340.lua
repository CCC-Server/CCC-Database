local s,id=GetID()

-----------------------------------------------------
-- ■ 전역 체인 체크: "스텔라론 헌터" 효과 발동 감지
-----------------------------------------------------
function s.global_check(e,tp,eg,ep,ev,re,r,rp)
    if re and re:GetHandler():IsSetCard(0xc47) then
        -- 이 턴에 스텔라론 헌터 카드의 효과가 발동되었음을 표시
        Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
    end
end


function s.initial_effect(c)

    -------------------------------------------------
    -- ★ 전역(Global) 효과 설치 (딱 1번만)
    -------------------------------------------------
    if not s.global_flag then
        s.global_flag = true
        local ge=Effect.CreateEffect(c)
        ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge:SetCode(EVENT_CHAINING)
        ge:SetOperation(s.global_check)
        Duel.RegisterEffect(ge,0)
    end


    -------------------------------------------------
    -- ① 패 특수 소환 (자신 턴/상대 턴: 스텔라론 헌터 효과 발동한 턴)
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetHintTiming(TIMINGS_CHECK_MONSTER_E)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)


    -------------------------------------------------
    -- ② 소환 성공: 선언 → 확인 → 파괴 → 엑시즈 진화
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.tg)
    e2:SetOperation(s.op)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
end


-----------------------------------------------------
-- ■ ① 패 특수 소환 조건
-----------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFlagEffect(tp,id)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end


-----------------------------------------------------
-- ■ ② 선언 → 확인 → 파괴 → 엑시즈 소환
-----------------------------------------------------

local type_map={
    [0]=TYPE_MONSTER,
    [1]=TYPE_SPELL,
    [2]=TYPE_TRAP
}

function s.xyzfilter(c,e,tp,mc)
    return c:IsSetCard(0xc47)
        and c:IsType(TYPE_XYZ)
        and c:IsRank(4)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,PLAYER_EITHER,LOCATION_ONFIELD)
end

function s.op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

    ------------------------------
    -- ① 카드 종류 선언
    ------------------------------
    Duel.Hint(HINT_SELECTMSG,tp,569)
    local ann=Duel.AnnounceType(tp)
    local real_type=type_map[ann]

    ------------------------------
    -- ② 덱 맨 위 공개
    ------------------------------
    Duel.ConfirmDecktop(1-tp,1)
    local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
    if not tc then return end
    local match = tc:IsType(real_type)

    ------------------------------
    -- ③ 필드 카드 1장 파괴
    ------------------------------
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    if #dg>0 then
        Duel.Destroy(dg,REASON_EFFECT)
    end

    ------------------------------
    -- ④ 선언이 맞으면 엑시즈 진화
    ------------------------------
    if not match then return end
    if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end

    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
    if #pg>1 or (#pg==1 and not pg:IsContains(c)) then return end

    if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
    if not xyz then return end

    Duel.BreakEffect()

    if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
        local mg=Group.FromCards(c)
        xyz:SetMaterial(mg)
        Duel.Overlay(xyz,mg)
        xyz:CompleteProcedure()
    end
end
