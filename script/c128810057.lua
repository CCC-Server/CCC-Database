--셀레스티얼 타이탄-실험하는 자 데브론
local s,id=GetID()
function s.initial_effect(c)
    -- 펜듈럼 소환
    Pendulum.AddProcedure(c)
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCondition(s.pencon)
    e1:SetTarget(s.pentg)
    e1:SetOperation(s.penop)
    c:RegisterEffect(e1)
    --Add 1 "Celestial Titan" Pendulum Monster to the hand
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
end

--천사족밖에 일반 소환 / 특수 소환 불가 맹세 효과
function s.splimit(e,c)
    return not c:IsRace(RACE_FAIRY)
end

s.listed_series={0xc02}
s.listed_names={id}
function s.cfilter(c)
    return c:IsSetCard(0xc02)
end
function s.pencon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_PZONE,0,1,e:GetHandler())
end
function s.penfilter(c)
    return c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM) and not c:IsCode(id) and not c:IsForbidden()
end
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.Destroy(e:GetHandler(),REASON_EFFECT)~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local g=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_DECK,0,1,1,nil)
        local tc=g:GetFirst()
        if tc then
            Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
        end
    end
end
function s.thfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xc02) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_EXTRA,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.exfilter(c)
    return c:IsSetCard(0xc02)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_EXTRA,0,1,1,nil)
    if #g==0 or Duel.SendtoHand(g,nil,REASON_EFFECT)==0 or not g:GetFirst():IsLocation(LOCATION_HAND) then return end
    Duel.ConfirmCards(1-tp,g)
    local sg=Duel.GetMatchingGroup(s.exfilter,tp,LOCATION_EXTRA,0,nil)
    if #sg==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,5)) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=sg:Select(tp,1,1,nil):GetFirst()
    if not sc then return end
end