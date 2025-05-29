--Cybernetic Convergence (가칭)
local s,id=GetID()
function s.initial_effect(c)
    -- ①: Activate freely + Search "Cyber Dragon" or "Cyberdark" monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- ②: Opponent cannot activate effects during Damage Step of Machine monster battle
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetRange(LOCATION_FZONE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(0,1)
    e2:SetCountLimit(1,id+100)
    e2:SetValue(s.aclimit)
    e2:SetCondition(s.battlecon)
    c:RegisterEffect(e2)

    -- ③: After Fusion Summoning a Machine Fusion Monster
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetRange(LOCATION_FZONE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id+200)
    e3:SetCondition(s.retcon)
    e3:SetTarget(s.rettg)
    e3:SetOperation(s.retop)
    c:RegisterEffect(e3)
end

-- ①: Activate and search "Cyber Dragon" or "Cyberdark" monster
function s.thfilter(c)
    return c:IsMonster() and (c:IsSetCard(SET_CYBER_DRAGON) or c:IsSetCard(0x4093)) and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:Select(tp,1,1,nil)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

-- ②: No effects during damage step if your Machine battles
function s.aclimit(e,re,tp)
    return re:IsHasType(EFFECT_TYPE_ACTIVATE+EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_QUICK_O)
end
function s.battlecon(e)
    local ph=Duel.GetCurrentPhase()
    local tc=Duel.GetAttacker()
    if not tc then return false end
    return tc:IsControler(e:GetHandlerPlayer()) and tc:IsRace(RACE_MACHINE)
        and (ph==PHASE_DAMAGE or ph==PHASE_DAMAGE_CAL)
end

-- ③: On Fusion Summon of Machine Fusion Monster
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(c) return c:IsSummonType(SUMMON_TYPE_FUSION)
        and c:IsRace(RACE_MACHINE) and c:IsControler(tp) end,1,nil)
end
function s.retfilter(c)
    return c:IsMonster() and c:IsAbleToHand() and c:ListsCode(70095154) -- Cyber Dragon
end
function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.retfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.retfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end
