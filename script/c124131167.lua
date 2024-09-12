--미스틱 드래곤
local s,id=GetID()
function s.initial_effect(c)
    c:EnableUnsummonable()
    --spsummon condition
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e4:SetCode(EFFECT_SPSUMMON_CONDITION)
    e4:SetValue(s.splimit)
    c:RegisterEffect(e4)
 	--Destroy 1 monster your opponent controls
     local e2=Effect.CreateEffect(c)
     e2:SetDescription(aux.Stringid(id,0))
     e2:SetCategory(CATEGORY_DESTROY)
     e2:SetType(EFFECT_TYPE_IGNITION)
     e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
     e2:SetRange(LOCATION_MZONE)
     e2:SetCountLimit(1,id)
     e2:SetCondition(s.rmcon)
     e2:SetCost(s.descost)
     e2:SetTarget(s.destg)
     e2:SetOperation(s.desop2)
     c:RegisterEffect(e2)
	--destroy replace
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
     --미스틱 베이비 드래곤 특수 소환.
     local e1=Effect.CreateEffect(c)
     e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
     e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
     e1:SetDescription(aux.Stringid(id,2))
     e1:SetCode(EVENT_TO_GRAVE)
     e1:SetCountLimit(1,{id,2})
     e1:SetCondition(function(e) return e:GetHandler():IsPreviousLocation(LOCATION_DECK) end)
     e1:SetTarget(s.target)
     e1:SetOperation(s.operation)
     c:RegisterEffect(e1)
end
s.listed_names={511009182}
function s.splimit(e,se,sp,st)
    return (se:GetHandler():IsCode(511009183) or se:GetHandler():IsCode(511009189))
        and (se:IsHasType(EFFECT_TYPE_ACTIONS) or se:GetCode()==EFFECT_SPSUMMON_PROC)
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeckAsCost(tp,3) end
	Duel.DiscardDeck(tp,3,REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop2(e,tp,eg,ep,ev,re,r,rp)
	local att=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g,true)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,511009182),tp,LOCATION_GRAVE,0,1,nil)
end

function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) and c:IsAttribute(ATTRIBUTE_LIGHT)
		and not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_EFFECT+REASON_BATTLE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end


function s.spfilter2(c,e,tp)
	return c:IsCode(511009183) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if e:GetHandler():GetSequence()<5 then ft=ft+1 end
	if chk==0 then return ft>0 and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetRange(LOCATION_MZONE)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetCondition(s.descon)
        e1:SetOperation(s.desop)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        e1:SetCountLimit(1)
        e:GetHandler():RegisterEffect(e1)
    end
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return not e:GetHandler():IsHasEffect(66235877)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end