-- 카드명: 불케닉 스프린더
-- Volcanic Sprinder
local s,id=GetID()
function s.initial_effect(c)
    -- ① 효과: 패/필드 → 묘지, 덱에서 "브레이즈 캐논" 세트
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.tgcost)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)
    
    -- ② 효과: 묘지에서 특소 + 상대 필드에 토큰 생성
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e2:SetType(EFFECT_TYPE_QUICK_O) -- 빠른 효과 (필드 체인 가능)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

-- ① 효과 코스트: 묘지로 보내기
function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

-- ① 효과 타겟: 덱에서 "브레이즈 캐논" 검색
function s.setfilter(c,tp)
    return c:IsCode(69537999) and c:IsContinuousSpellTrap() and not c:IsForbidden()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil,tp) end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_DECK,nil,1,tp,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
    if tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end

-- ② 효과 조건: 자신 필드에 "브레이즈 캐논" 존재
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_SZONE,0,1,nil)
end
function s.cfilter(c)
    return c:IsFaceup() and c:IsCode(69537999) -- "Volcanic Blaze Accelerator" ID
end

-- ② 효과 실행: 토큰 생성 + 자신 특소
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,1000,1000,1,RACE_PYRO,ATTRIBUTE_FIRE,POS_FACEUP,1-tp)
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    -- 상대 필드에 토큰 생성
    if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end
    local token=Duel.CreateToken(tp,id+1)
    if Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP) then
        -- 토큰 속성/능력치 설정 (생략 가능)
    end
    
    -- 자신의 묘지에서 이 카드 특소
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end
