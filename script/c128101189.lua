local s,id=GetID()
s.listed_names={CARD_FLAME_SWORDSMAN} -- 🔹 이 카드는 "화염의 검사" 카드명을 참조함을 명시

function s.initial_effect(c)
    -- E1: 서치 효과 (Ignition + 조건부 Quick)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- E1-Quick 버전: 조건부 (필드에 화염의 검사 있을 때)
    local e1q=Effect.CreateEffect(c)
    e1q:SetDescription(aux.Stringid(id,0))
    e1q:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1q:SetType(EFFECT_TYPE_QUICK_O)
    e1q:SetCode(EVENT_FREE_CHAIN)
    e1q:SetRange(LOCATION_HAND)
    e1q:SetCountLimit(1,id)
    e1q:SetCondition(s.qcon)
    e1q:SetCost(s.thcost)
    e1q:SetTarget(s.thtg)
    e1q:SetOperation(s.thop)
    c:RegisterEffect(e1q)

    -- E2: 묘지에서 특수 소환
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

-- 🔸E1 관련 함수

-- 코스트: 자신을 묘지로 보낸다
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToGraveAsCost() end
    Duel.SendtoGrave(c,REASON_COST)
end

-- 덱에서 "화염의 검사" 언급 마/함 서치
function s.thfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:ListsCode(CARD_FLAME_SWORDSMAN) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- Quick 발동 조건: 내가 "화염의 검사" 컨트롤 중
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cnamefilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.cnamefilter(c)
    return c:IsFaceup() and c:ListsCode(CARD_FLAME_SWORDSMAN)
end

-- 🔸E2 관련 함수

-- 전사족 몬스터 존재 시 발동 가능
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,RACE_WARRIOR),tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if c:IsRelateToEffect(e) then
        if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
            -- 어둠 속성으로 취급
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_ADD_ATTRIBUTE)
            e1:SetValue(ATTRIBUTE_DARK)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e1)
        end
    end
end
