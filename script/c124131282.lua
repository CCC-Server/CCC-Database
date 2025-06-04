--스완송 아구아
local s,id=GetID()
function s.initial_effect(c)
    --①: 패에서 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --②: 엑시즈 몬스터 효과 부여 - 묘지 발동 무효
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.negcon)
    e2:SetCost(s.negcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
end

--①: 패에서 특수 소환 조건: 다른 레벨 2 물 몬스터가 패에 있어야 함
function s.spfilter(c,e,tp)
    return c:IsLevel(2) and c:IsAttribute(ATTRIBUTE_WATER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,e:GetHandler(),e,tp)
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,c,e,tp)
    if #g>0 then
        Duel.ConfirmCards(1-tp,g)
        local tc=g:GetFirst()
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
        local sg=Group.FromCards(c,tc)
        Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
    end
end

--②: 소재로 있을 때, 상대 묘지 발동 무효 효과
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetOwner()
    if not (rc:IsType(TYPE_XYZ) and rc:IsAttribute(ATTRIBUTE_WATER)) then return false end
    return rp==1-tp and re:IsActivated() and re:GetActivateLocation()==LOCATION_GRAVE
end

-- 1턴 1회 체크 (비용 처리 방식 사용)
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return not e:GetHandler():IsStatus(STATUS_CHAINING) end
    e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end