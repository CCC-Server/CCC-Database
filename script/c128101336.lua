local s,id=GetID()
function s.initial_effect(c)

    --------------------------------
    -- ① 패 공개 → 패 특수 소환
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,1})
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --------------------------------
    -- ② 일소/특소 성공 → 선언 + 공개 + 서치 + 조건부 엑시즈
    --------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,2})
    e2:SetTarget(s.xztg)
    e2:SetOperation(s.xzop)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
end

--------------------------------
-- ① 패 공개 → 패 특수 소환
--------------------------------
function s.cfilter(c)
    return c:IsSetCard(0xc47) and c:IsType(TYPE_MONSTER)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,1,nil)
    local tc=g:GetFirst()
    Duel.ConfirmCards(1-tp,tc)

    e:SetLabelObject(tc)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.SpecialSummon(e:GetHandler(),0,tp,tp,false,false,POS_FACEUP)
end

--------------------------------
-- ② 서치용 필터
--------------------------------
function s.stfilter(c)
    return c:IsSetCard(0xc47) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

--------------------------------
-- ③ 엑시즈용 필터
--------------------------------
function s.xyzfilter(c,e,tp,mc)
    return c:IsSetCard(0xc47)
        and c:IsRank(4)
        and c:IsType(TYPE_XYZ)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

--------------------------------
-- 선언 값 매핑
--------------------------------
local type_map={
    [0]=TYPE_MONSTER,
    [1]=TYPE_SPELL,
    [2]=TYPE_TRAP
}

--------------------------------
-- ② Target
--------------------------------
function s.xztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 end

    Duel.Hint(HINT_SELECTMSG,tp,569)
    local ann=Duel.AnnounceType(tp) -- 0=Monster,1=Spell,2=Trap
    e:SetLabel(ann)

    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--------------------------------
-- ② Operation
--------------------------------
function s.xzop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ann=e:GetLabel()
    local t=type_map[ann] -- TYPE_MONSTER / TYPE_SPELL / TYPE_TRAP

    --------------------------
    -- Step 1: 상대 덱 위 1장 확인
    --------------------------
    local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
    if not tc then return end

    Duel.ConfirmCards(tp,tc)

    local match = tc:IsType(t)

    --------------------------
    -- Step 2: 덱에서 "스텔라론 헌터" 마/함 서치 (무조건)
    --------------------------
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local sg=Duel.SelectMatchingCard(tp,s.stfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #sg>0 then
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end

    --------------------------
    -- Step 3: 일치하면 엑시즈 진화
    --------------------------
    if not match then return end
    if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end

    -- Purrely식 MustBeMaterialGroup 체크
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
    if #pg>1 or (#pg==1 and not pg:IsContains(c)) then return end

    if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then return end

    -- 선택
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
    if not xyz then return end

    Duel.BreakEffect()

    -- Xyz 처리
    if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
        local mg=Group.FromCards(c)
        xyz:SetMaterial(mg)
        Duel.Overlay(xyz,mg)
        xyz:CompleteProcedure()
    end
end
