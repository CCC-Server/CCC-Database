--영원한 후일담의 펜던트
local s,id=GetID()
function s.initial_effect(c)
    --cannot attack
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_ATTACK)
    c:RegisterEffect(e1)
    --self destroy
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_SELF_DESTROY)
    e2:SetCondition(s.descon)
    c:RegisterEffect(e2)
    --destroy replace
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTarget(s.destg)
    e3:SetValue(s.desval)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)
    --negate effect
    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.discon)
    e4:SetTarget(s.distg)
    e4:SetOperation(s.disop)
    c:RegisterEffect(e4)
    --Opponent cannot target this card for attacks
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetValue(aux.imval2)
    c:RegisterEffect(e5)
    --Search Level 8 or lower monster and Normal summon
    local e6=Effect.CreateEffect(c)
    e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCode(EVENT_DESTROYED)
    e6:SetCondition(s.thcon)
    e6:SetTarget(s.thtg)
    e6:SetOperation(s.thop)
    c:RegisterEffect(e6)
end
function s.filter(c)
    return c:IsFaceup() and c:IsType(TYPE_NORMAL) and c:IsRace(RACE_ZOMBIE)
end
function s.descon(e)
    return not Duel.IsExistingMatchingCard(s.filter,e:GetHandler():GetControler(),LOCATION_MZONE,0,1,nil)
end
function s.desfilter(c,tp)
    return s.filter(c) and c:IsLocation(LOCATION_MZONE)
        and not c:IsReason(REASON_REPLACE) and c:IsControler(tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return not eg:IsContains(e:GetHandler())
        and eg:IsExists(s.desfilter,1,nil,tp) end
    if Duel.SelectEffectYesNo(tp,e:GetHandler(),96) then
        return true
    else return false end
end
function s.desval(e,c)
    return s.filter(c) and c:IsLocation(LOCATION_MZONE)
        and not c:IsReason(REASON_REPLACE) and c:IsControler(e:GetHandlerPlayer())
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    return ep~=tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainDisablable(ev)
        and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsDestructable() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateEffect(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg,REASON_EFFECT)
    end
end 
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return r&REASON_EFFECT~=0
end 
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end 
function s.thfilter(c)
    return ((c:IsSetCard(0x1fd0)) or (c:IsType(TYPE_NORMAL)) and (c:IsRace(RACE_ZOMBIE))) and (c:IsType(TYPE_MONSTER)) and (c:IsAbleToHand()) and (c:IsLevelBelow(8))
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    local sg1=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_HAND,0,nil)
        if #sg1>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            Duel.BreakEffect()
            Duel.ShuffleHand(tp)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
            local sg2=sg1:Select(tp,1,1,nil):GetFirst()
            Duel.Summon(tp,sg2,true,nil)
        end
    end
end