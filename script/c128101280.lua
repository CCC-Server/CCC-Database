--Custom Barrel Support Monster
local s,id=GetID()
function s.initial_effect(c)
    --① Special Summon if added to hand (not by draw)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --② Add 1 "Barrel" Spell/Trap on Summon, DARK Lock
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    --③ Negate from GY (if Link4 Barrel exists)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_NEGATE)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,2})
    e4:SetCondition(s.negcon)
    e4:SetCost(s.negcost)
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)
end
s.listed_series={0x10f} -- "Barrel" archetype

-----------------------------------------------------
--① Special Summon if added to hand (not by draw)
-----------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return not (r&REASON_DRAW)~=0 and re and re:GetHandler()~=c and c:IsPreviousLocation(LOCATION_DECK+LOCATION_GRAVE)
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
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-----------------------------------------------------
--② Search "Barrel" Spell/Trap + DARK Lock
-----------------------------------------------------
function s.thfilter(c)
    return c:IsSetCard(0x10f) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end

    --DARK-only restriction for rest of turn
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    --Hint
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,3))
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e2:SetCode(0)
    e2:SetTargetRange(1,0)
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end
function s.splimit(e,c)
    return c:IsLocation(LOCATION_EXTRA) and not c:IsAttribute(ATTRIBUTE_DARK)
end

-----------------------------------------------------
--③ Negate Monster Effect from GY (if Link4 Barrel exists)
-----------------------------------------------------
function s.l4barrel(c)
    return c:IsSetCard(0x10f) and c:IsType(TYPE_LINK) and c:GetLink()>=4
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if tp==rp or not re:IsActivated() or not re:IsMonsterEffect() then return false end
    if not Duel.IsChainNegatable(ev) then return false end
    return Duel.IsExistingMatchingCard(s.l4barrel,tp,LOCATION_MZONE,0,1,nil)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end
