--주술회전 후시구로 메구미
local s,id=GetID()
function s.initial_effect(c)
    -- Can be used as the entire requirement for the Ritual Summon of a LIGHT Warrior or Dragon Ritual Monster
    Ritual.AddWholeLevelTribute(c,aux.FilterBoolFunction(Card.IsSetCard,0xc41))
    
    -- Special Summon itself from the hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id) -- 1턴에 1번 사용 가능
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Apply the effects of a "Ritual" spell
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(function(_,tp) return Duel.IsTurnPlayer(1-tp) end)
    e2:SetCost(s.ritcost)
    e2:SetTarget(s.rittg)
    e2:SetOperation(s.ritop)
    c:RegisterEffect(e2)
end    
    s.listed_series={0xc41}
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xc41),tp,LOCATION_ONFIELD,0,1,nil)
end

function s.thfilter(c)
    return c:IsSetCard(0xc41) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSSetable() and not c:IsCode(id)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then 
        return c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
        and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.BreakEffect()
        Duel.SSet(tp,g:GetFirst()) -- Set the selected card
        Duel.ConfirmCards(1-tp,g)
    end
end

function s.ritcost(e,tp,eg,ep,ev,re,r,rp,chk)
    e:SetLabel(1)
    return true
end

function s.ritfilter(c)
    return c:IsAbleToGraveAsCost() and c:IsSetCard(0xc41) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_RITUAL) and c:CheckActivateEffect(true,true,false)~=nil
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        if e:GetLabel()==0 then return false end
        e:SetLabel(0)
        return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_DECK,0,1,nil)
    end
    e:SetLabel(0)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local tc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
    local te=tc:CheckActivateEffect(true,true,false)
    e:SetLabelObject(te)
    Duel.SendtoGrave(tc,REASON_COST)
    e:SetProperty(te:GetProperty())
    local tg=te:GetTarget()
    if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
    Duel.ClearOperationInfo(0)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
    local te=e:GetLabelObject()
    if not te then return end
    local op=te:GetOperation()
    if op then op(e,tp,eg,ep,ev,re,r,rp) end
end

