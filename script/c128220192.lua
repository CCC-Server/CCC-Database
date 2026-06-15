--비르투스-클라이맥스
local s,id=GetID()
function c128220192.initial_effect(c)
--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ②: 서로의 메인 페이즈에 자신 필드의 마법사족 1장과 필드의 앞면 표시 카드 1장을 파괴.
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.descon)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)

    -- ③: 배틀 페이즈 동안에만 자신 필드의 "비르투스" 몬스터의 공/수 1000 업.
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetCondition(s.atkcon)
    e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xc29))
    e3:SetValue(1000)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)
end

-- 카드군 관계 설정
s.listed_series={0xc29}

-- ①번 효과: 스탠바이 페이즈 조건 및 필터
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentPhase()==PHASE_STANDBY
end
function s.spfilter(c,e,tp)
    return c:IsSetCard(0xc29) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
    end
end

-- ②번 효과: 메인 페이즈 조건 및 필터
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_MAIN1 and ph<=PHASE_MAIN2
end
function s.desfilter1(c)
    return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)
end
function s.desfilter2(c)
    return c:IsFaceup()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsExistingTarget(s.desfilter1,tp,LOCATION_MZONE,0,1,nil)
        and Duel.IsExistingTarget(s.desfilter2,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g1=Duel.SelectTarget(tp,s.desfilter1,tp,LOCATION_MZONE,0,1,1,nil)
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    -- 자신 필드의 마법사족을 다시 찍을 수도 있으므로 g1에 선택된 카드를 제외하지 않고 전체에서 고릅니다.
    local g2=Duel.SelectTarget(tp,s.desfilter2,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,g1:GetFirst())
    
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,2,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

-- ③번 효과: 배틀 페이즈 조건
function s.atkcon(e)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end
