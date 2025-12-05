local s,id=GetID()
function s.initial_effect(c)

    -----------------------------------------
    -- Effect 1: Hand Special Summon (Quick Effect)
    -----------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -----------------------------------------
    -- Effect 2: Declare → Reveal → Banish → Xyz Evolution
    -----------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.operation_tg)
    e2:SetOperation(s.operation)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
end

-----------------------------------------
-- E1: Special Summon from Hand
-----------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    -- Opponent controls any face-up monster
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsMonster),tp,0,LOCATION_MZONE,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-----------------------------------------
-- E2: Declare → Reveal → Banish → Conditional Xyz Evolution
-----------------------------------------

local type_map={
    [0]=TYPE_MONSTER,
    [1]=TYPE_SPELL,
    [2]=TYPE_TRAP
}

function s.operation_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 end
end

function s.xyzfilter(c,e,tp,mc)
    return c:IsSetCard(0xc47)
        and c:IsType(TYPE_XYZ)
        and c:IsRank(4)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

    ----------------------------
    -- Step 1: Declare type
    ----------------------------
    Duel.Hint(HINT_SELECTMSG,tp,569)
    local ann=Duel.AnnounceType(tp)
    local real_type=type_map[ann]

    ----------------------------
    -- Step 2: Reveal opponent’s top card  (NO SHUFFLE!)
    ----------------------------
    Duel.ConfirmDecktop(1-tp,1)
    local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
    if not tc then return end

    local match = tc:IsType(real_type)

    ----------------------------
    -- Step 3: Banish that card face-down (NO SHUFFLE!)
    ----------------------------
    Duel.DisableShuffleCheck()
    Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)

    ----------------------------
    -- Step 4: If matched → Xyz Evolution
    ----------------------------
    if not match then return end
    if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end

    -- Purrely-style must-material check
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
    if #pg>1 or (#pg==1 and not pg:IsContains(c)) then return end

    if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then return end

    ----------------------------
    -- Step 5: Select Rank 4 Stellaron Hunter Xyz
    ----------------------------
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
    if not xyz then return end

    Duel.BreakEffect()

    ----------------------------
    -- Step 6: Xyz Evolution
    ----------------------------
    if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
        local mg=Group.FromCards(c)
        xyz:SetMaterial(mg)
        Duel.Overlay(xyz,mg)
        xyz:CompleteProcedure()
    end
end
