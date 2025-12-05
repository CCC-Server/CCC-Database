local s,id=GetID()
function s.initial_effect(c)

    --------------------------------
    -- Effect 1: Special Summon Procedure
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    --------------------------------
    -- Effect 2: Declare → Reveal → Search → Xyz Evolution
    --------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.xztg)
    e2:SetOperation(s.xzop)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
end

-----------------------
-- Effect 1
-----------------------
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xc47)
end

function s.spcon(e,c)
    if c==nil then return true end
    return Duel.IsExistingMatchingCard(s.cfilter,c:GetControler(),LOCATION_MZONE,0,1,nil)
end

-----------------------
-- Filters
-----------------------
function s.thfilter(c)
    return c:IsSetCard(0xc47) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.xyzfilter(c,e,tp,mc)
    return c:IsSetCard(0xc47)
        and c:IsRank(4)
        and c:IsType(TYPE_XYZ)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

-----------------------
-- Effect 2
-----------------------
-- AnnounceType returns: 0=Monster, 1=Spell, 2=Trap
local type_map={
    [0]=TYPE_MONSTER,
    [1]=TYPE_SPELL,
    [2]=TYPE_TRAP
}

function s.xztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 end

    Duel.Hint(HINT_SELECTMSG,tp,569)
    local ann=Duel.AnnounceType(tp) -- 0/1/2
    e:SetLabel(ann)

    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xzop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ann=e:GetLabel()
    local t=type_map[ann]

    ----------------------------
    -- Step 1: Reveal opponent's top card (NO SHUFFLE!)
    ----------------------------
    Duel.ConfirmDecktop(1-tp,1)
    local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
    if not tc then return end

    local match = tc:IsType(t)

    ----------------------------
    -- Step 2: Search “스텔라론 헌터” Monster (Always)
    ----------------------------
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #sg>0 then
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end

    ----------------------------
    -- Step 3: If matched → Xyz Evolution
    ----------------------------
    if not match then return end
    if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end

    -- MustBeMaterialGroup check (Purrely-style)
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
    if #pg>1 or (#pg==1 and not pg:IsContains(c)) then return end

    if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then return end

    -- Select Xyz Monster
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
    if not xyz then return end

    Duel.BreakEffect()

    -- Xyz Evolution
    if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
        local mg=Group.FromCards(c)
        xyz:SetMaterial(mg)
        Duel.Overlay(xyz,mg)
        xyz:CompleteProcedure()
    end
end
