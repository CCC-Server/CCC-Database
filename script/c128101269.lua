--Buster Supporter (가칭)
local s,id=GetID()
local CARD_ASSAULT_MODE=80280737 -- "버스터 모드"
local SET_ASSAULT_MODE=0x104F -- "버스터" 카드군 (정의 수정됨)

function s.initial_effect(c)
    --①: 패 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_HAND)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --추가: 자신 필드에 싱크로 몬스터가 있을 경우도 발동 가능
    local e1b=e1:Clone()
    e1b:SetType(EFFECT_TYPE_IGNITION)
    e1b:SetCode(0) -- IGNITION은 Free Chain 이벤트 없음
    e1b:SetCondition(s.fieldspcon)
    c:RegisterEffect(e1b)

    --②: 무효 + 부활
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.negcon)
    e2:SetCost(aux.bfgcost) -- this removes the card from GY
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)

    --③: 싱크로 소재시 튜너 이외로 취급
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_NONTUNER)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(1)
    c:RegisterEffect(e3)
end

s.listed_names={CARD_ASSAULT_MODE}
s.listed_series={SET_ASSAULT_MODE}

---------------------------------------------------------------
-- ① 드로우 이외 패에 들어왔을 때 또는 필드에 싱크로 몬스터 존재 시 특소
---------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return eg:IsContains(c) and (not re or not re:IsHasCategory(CATEGORY_DRAW))
end
function s.fieldspcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_SYNCHRO)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

---------------------------------------------------------------
-- ② 마/함 효과 발동 무효 + "버스터 모드" 언급 몬스터 부활
---------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsChainNegatable(ev)
        and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
        and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_SYNCHRO)
end
function s.spfilter(c,e,tp)
    return c:IsMonster() and c:ListsCode(CARD_ASSAULT_MODE)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end
