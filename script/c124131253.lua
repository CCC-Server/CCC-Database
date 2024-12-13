--대사신 조크 네크로파데스
local s,id=GetID()
function s.initial_effect(c)
    -- Cannot be special summoned except by "앙크의 석판"
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.FALSE)
    c:RegisterEffect(e0)
    
    -- Special summon condition
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetTarget(s.skiptg)
	e1:SetOperation(s.skipop)
	c:RegisterEffect(e1)
    
    -- Immune to other card effects and ATK/DEF update
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.immval)
    c:RegisterEffect(e2)
    
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.adval)
    c:RegisterEffect(e3)
    
    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)
    
    -- Banish when leaves field
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
    e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e5:SetCondition(s.recon)
    e5:SetValue(LOCATION_REMOVED)
    c:RegisterEffect(e5)
    
    -- Check and destroy a card in opponent's hand
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
    e6:SetCondition(s.descon)
	e6:SetOperation(s.hdop)
	c:RegisterEffect(e6)
end

function s.skiptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(1-tp,EFFECT_SKIP_TURN) end
end
function s.skipop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_SKIP_TURN)
	e1:SetTargetRange(0,1)
	e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
	e1:SetCondition(s.skipcon)
	Duel.RegisterEffect(e1,tp)
end
function s.skipcon(e)
	return Duel.GetTurnPlayer()~=e:GetHandlerPlayer()
end
function s.immval(e,te)
    return te:GetOwner()~=e:GetHandler()
end

function s.adval(e,c)
    local g=Duel.GetMatchingGroup(Card.ListsCode,c:GetControler(),LOCATION_REMOVED,0,nil,124131244)
    return g:GetClassCount(Card.GetCode)*1000
end

function s.recon(e)
    return e:GetHandler():IsFaceup()
end

function s.hdestroy(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)==0 then return end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    Duel.ConfirmCards(tp,g)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local sg=g:Select(tp,1,1,nil)
    Duel.Destroy(sg,REASON_EFFECT)
    Duel.ShuffleHand(1-tp)
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE)
end
function s.hdop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)==0 then return end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    Duel.ConfirmCards(tp,g)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local sg=g:Select(tp,1,1,nil)
    Duel.Destroy(sg,REASON_EFFECT)
    Duel.ShuffleHand(1-tp)
end