--Armed Dragon Thunder Emperor
local s,id=GetID()
function s.initial_effect(c)
    -- 융합 몬스터 기본 설정
    c:EnableReviveLimit()
    --------------------------------
    -- 특수 소환 규칙: 엑스트라 덱에서만 / 필드의 재료를 묘지로 보내고 특소
    --------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.spcon)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)

    --------------------------------
    -- ① 특수 소환 성공 시: "Armed Dragon" 마/함 세트 (강제)
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    -- CATEGORY_TOFIELD 가 일부 코어에서 nil일 수 있어서 0으로 처리
    e1:SetCategory(0)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)

    --------------------------------
    -- ② 공격 선언 시: 데미지 스텝 종료까지 상대는 마/함/몬스터 효과 발동 불가
    --------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ATTACK_ANNOUNCE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.atkcon)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)

    --------------------------------
    -- ③ 퀵: 자신 릴리스 → 덱/묘지의 LV10 이하 "Armed Dragon" 특소 + 상대 카드 1장 파괴
    --------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    -- 필요하면 이름 있는 1턴 1번 넣고 싶을 때: e3:SetCountLimit(1,id)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop2)
    c:RegisterEffect(e3)
end

--------------------------------
-- 공용: "Armed Dragon" 세트코드 (0x111 가정)
--------------------------------
function s.isAD(c)
    return c:IsSetCard(0x111)
end

--------------------------------
-- 특소 규칙: 필드에서
--  재료: 1장 "Armed Dragon" 몬스터 + 1장 WIND 드래곤 몬스터
--  둘 다 자신 필드에서 묘지로 보내고 엑덱에서 특수 소환
--------------------------------
function s.matfilter_ad(c)
    return c:IsFaceup() and s.isAD(c) and c:IsType(TYPE_MONSTER)
        and c:IsAbleToGraveAsCost()
end
function s.matfilter_wind(c,ex)
    return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsAttribute(ATTRIBUTE_WIND)
        and c:IsType(TYPE_MONSTER)
        and c:IsAbleToGraveAsCost()
        and c~=ex
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    -- 엑덱에서의 몬스터 존 체크
    if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then return false end
    -- 자신 필드에 재료가 있는지 확인
    local g1=Duel.GetMatchingGroup(s.matfilter_ad,tp,LOCATION_MZONE,0,nil)
    if #g1==0 then return false end
    for tc in aux.Next(g1) do
        if Duel.IsExistingMatchingCard(s.matfilter_wind,tp,LOCATION_MZONE,0,1,tc,tc) then
            return true
        end
    end
    return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    -- 먼저 "Armed Dragon" 몬스터 선택
    local g1=Duel.SelectMatchingCard(tp,s.matfilter_ad,tp,LOCATION_MZONE,0,1,1,nil)
    local tc1=g1:GetFirst()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    -- 그 다음 WIND 드래곤 몬스터 선택 (첫 카드와는 다른 카드)
    local g2=Duel.SelectMatchingCard(tp,s.matfilter_wind,tp,LOCATION_MZONE,0,1,1,tc1,tc1)
    g1:Merge(g2)
    c:SetMaterial(g1)
    -- 재료를 묘지로 보냄 (융합 소재 + 코스트 취급)
    Duel.SendtoGrave(g1,REASON_COST+REASON_MATERIAL+REASON_FUSION)
end

--------------------------------
-- ① 특수 소환 성공 시: "Armed Dragon" 마/함 세트 (강제)
--------------------------------
function s.setfilter(c)
    return s.isAD(c) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,0,nil,1,tp,LOCATION_DECK)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if not Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SSet(tp,g)
        Duel.ConfirmCards(1-tp,g)
    end
end

--------------------------------
-- ② 이 카드가 공격 선언했을 때: 데미지 스텝 종료까지 상대는 마/함/몬스터 효과 발동 불가
--------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return Duel.GetAttacker()==c
end
function s.aclimit(e,re,tp)
    return re:IsActiveType(TYPE_SPELL+TYPE_TRAP+TYPE_MONSTER)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToBattle() then return end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(0,1)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_DAMAGE)
    Duel.RegisterEffect(e1,tp)
end

--------------------------------
-- ③ 퀵: 자신 릴리스 → 덱/묘지의 LV10 이하 "Armed Dragon" 특소 + 상대 카드 1장 파괴
--------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsReleasable() end
    Duel.Release(c,REASON_COST)
end

function s.spfilter(c,e,tp)
    return s.isAD(c) and c:IsLevelBelow(10)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,true) -- 소환 조건 무시
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
    if #g==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=g:Select(tp,1,1,nil)
    local tc=sg:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,true,POS_FACEUP)~=0 then
        -- 그 후, 상대 필드의 카드 1장 파괴 (텍스트에 "you can"이 없으므로 강제)
        local dg=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
        if #dg>0 then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
            local g2=dg:Select(tp,1,1,nil)
            Duel.HintSelection(g2,true)
            Duel.Destroy(g2,REASON_EFFECT)
        end
    end
end
