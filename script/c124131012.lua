--데 리퍼 ADR-07 팔레츠헤드
local s,id=GetID()
function s.initial_effect(c)
	c:EnableUnsummonable()
	c:SetUniqueOnField(1,0,id)
	--spsummon condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)
    --effectno
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.con3)
    e3:SetTarget(s.target)
    e3:SetOperation(s.operation)
    c:RegisterEffect(e3)
    --cannot spsummon
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetTargetRange(0,1)
	e4:SetCondition(s.discon)
	e4:SetTarget(s.splimit2)
	c:RegisterEffect(e4)
end
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsSetCard(0x810)
		and (se:IsHasType(EFFECT_TYPE_ACTIONS) or se:GetCode()==EFFECT_SPSUMMON_PROC)
end

function s.con3(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
    if chk==0 then return Duel.IsExistingTarget(nil,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,nil,tp,0,LOCATION_MZONE,1,1,nil)
   end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e)  then
     local e2=Effect.CreateEffect(e:GetHandler())
     e2:SetType(EFFECT_TYPE_SINGLE)
     e2:SetCode(EFFECT_CANNOT_ATTACK)
     e2:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,2)
     tc:RegisterEffect(e2)
     local e3=Effect.CreateEffect(e:GetHandler())
     e3:SetType(EFFECT_TYPE_SINGLE)
     e3:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
     e3:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,2)
     tc:RegisterEffect(e3)
     local e4=Effect.CreateEffect(e:GetHandler())
     e4:SetType(EFFECT_TYPE_SINGLE)
     e4:SetCode(EFFECT_DISABLE)
     e4:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,2)
     tc:RegisterEffect(e4)
     local e5=Effect.CreateEffect(e:GetHandler())
     e5:SetType(EFFECT_TYPE_SINGLE)
     e5:SetCode(EFFECT_DISABLE_EFFECT)
     e5:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,2)
     tc:RegisterEffect(e5)
    end
   end

function s.discon(e)
    return Duel.IsExistingMatchingCard(Card.IsCode,e:GetHandlerPlayer(),LOCATION_FZONE,0,1,nil,124131004)
end
function s.splimit2(e,c)
	return c:IsLocation(LOCATION_HAND)
end