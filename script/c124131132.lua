--The Tower 30th Floor
local s,id=GetID()
function s.initial_effect(c)
    --Must be properly summoned before reviving
    c:EnableReviveLimit()
    --Xyz summon procedure
	Xyz.AddProcedure(c,nil,4,2,nil,nil,99)
    --Gains ATK/DEF equal to the total ATK/DEF of the "The Tower" monsters attached
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)
    local e3=e1:Clone()
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    e3:SetValue(s.defval)
    c:RegisterEffect(e3)
    --Attach the top 5 cards of your Deck to this card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_CONTROL+CATEGORY_DAMAGE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ) end)
    e2:SetTarget(s.atchtg)
    e2:SetOperation(s.atchop)
    c:RegisterEffect(e2)
    --act limit
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetCode(EFFECT_CANNOT_ACTIVATE)
    e4:SetCondition(s.con)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(0,1)
    e4:SetValue(s.aclimit)
    c:RegisterEffect(e4)
end

function s.atkfilter(c)
    return c:IsSetCard(0x81e) and c:GetAttack()>=0
end

function s.atkval(e,c)
    local g=e:GetHandler():GetOverlayGroup():Filter(s.atkfilter,nil)
    return g:GetSum(Card.GetAttack)
end

function s.deffilter(c)
    return c:IsSetCard(0x81e) and c:GetDefense()>=0
end

function s.defval(e,c)
    local g=e:GetHandler():GetOverlayGroup():Filter(s.deffilter,nil)
    return g:GetSum(Card.GetDefense)
end

function s.atchtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsType(TYPE_XYZ) and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,c,1,1-tp,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,400)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,tp,LOCATION_MZONE)
end

function s.atchop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetDecktopGroup(tp,5)
    if not (c:IsRelateToEffect(e) and #g==5) then return end
    Duel.DisableShuffleCheck()
    Duel.Overlay(c,g)
end

function s.con(e)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

function s.aclimit(e,re,tp)
    return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end