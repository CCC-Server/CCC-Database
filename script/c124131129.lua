--The Tower of End
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    --xyz summon
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.tg1)
    e2:SetOperation(s.op1)
    c:RegisterEffect(e2)
end

function s.filter(c,e,tp)
    return c:IsRace(RACE_ROCK) and c:IsCanBeEffectTarget(e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.xyzfilter(c,mg,tp,chk)
    return c:IsXyzSummonable(nil,mg,2,2) and (not chk or Duel.GetLocationCountFromEx(tp,tp,mg,c)>0)
end

function s.mfilter1(c,mg,exg,tp)
    return mg:IsExists(s.mfilter2,1,c,c,exg,tp)
end

function s.zonecheck(c,tp,g)
    return Duel.GetLocationCountFromEx(tp,tp,g,c)>0 and c:IsXyzSummonable(nil,g)
end

function s.mfilter2(c,mc,exg,tp)
    local g=Group.FromCards(c,mc)
    return exg:IsExists(s.zonecheck,1,nil,tp,g)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    local mg=Duel.GetMatchingGroup(s.filter,tp,LOCATION_GRAVE,0,nil,e,tp)
    local exg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,mg)
    if chk==0 then return Duel.IsPlayerCanSpecialSummonCount(tp,2)
        and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
        and mg:IsExists(s.mfilter1,1,nil,mg,exg,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg1=mg:FilterSelect(tp,s.mfilter1,1,1,nil,mg,exg,tp)
    local tc1=sg1:GetFirst()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg2=mg:FilterSelect(tp,s.mfilter2,1,1,tc1,tc1,exg,tp)
    sg1:Merge(sg2)
    Duel.SetTargetCard(sg1)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,sg1,2,0,0)
end

function s.filter2(c,e,tp)
    return c:IsRelateToEffect(e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(s.filter2,nil,e,tp)
    if #g<2 then return end
    Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    Duel.BreakEffect()
    local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,g,tp,true)
    if #xyzg>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
        Duel.XyzSummon(tp,xyz,nil,g)
    end
end

function s.tg1filter(c,e,tp)
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
    return (#pg<=0 or (#pg==1 and pg:IsContains(c))) and c:IsFaceup() and c:IsSetCard(0x81e) and Duel.IsExistingMatchingCard(s.tg1xfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,pg)
end

function s.tg1xfilter(c,e,tp,mc,pg)
    if c.rum_limit and not c.rum_limit(mc,e) then return false end
    return c:IsSetCard(0x81e) and c:IsType(TYPE_XYZ) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0 and mc:IsCanBeXyzMaterial(c) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.tg1filter(chkc,e,tp) end
    if chk==0 then return Duel.IsExistingTarget(s.tg1filter,tp,LOCATION_MZONE,0,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.tg1filter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(tc),tp,nil,nil,REASON_XYZ)
    if tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsControler(1-tp) or tc:IsImmuneToEffect(e) or #pg>1 or (#pg==1 and not pg:IsContains(tc)) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=Duel.SelectMatchingCard(tp,s.tg1xfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc,pg):GetFirst()
    if sc then
        sc:SetMaterial(Group.FromCards(tc))
        Duel.Overlay(sc,Group.FromCards(tc))
        Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
        sc:CompleteProcedure()
    end
end