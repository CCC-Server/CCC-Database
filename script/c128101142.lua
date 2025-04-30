--카드명: 불케닉 스프린더
--Volcanic Sprinder
local s,id=GetID()
function s.initial_effect(c)
    -- ① 패/필드 → 묘지, 덱에서 "브레이즈 캐논" 지속 마/함 세트
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE)  -- 여기에 카테고리 설정
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.tgcost)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)

    -- ② 묘지에서 발동: 상대 필드에 토큰 특소 + 자신 부활
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)  -- 여기에 카테고리 설정
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

s.listed_series={SET_VOLCANIC,SET_BLAZE_ACCELERATOR}
s.listed_names={id,TOKEN_BOMB}

-- ① 코스트: 자신을 묘지로
function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

-- ① 타겟: 덱에서 "브레이즈 캐논" 지속 마/함 존재 여부 확인
function s.setfilter(c)
    return c:IsSetCard(SET_BLAZE_ACCELERATOR) and c:IsContinuousSpellTrap() and not c:IsForbidden()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
           and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

-- ① 처리: 덱에서 브레이즈 캐논 지속 마/함 1장 앞면으로 세트
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end

-- ② 조건: 자신의 마법 & 함정 존에 "브레이즈 캐논" 카드가 앞면 존재
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(SET_BLAZE_ACCELERATOR)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_SZONE,0,1,nil)
end

-- ② 대상: 토큰과 자신 모두 특수 소환 가능 여부 확인
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
           and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
           and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_BOMB,0,TYPES_TOKEN,1000,1000,1,RACE_PYRO,ATTRIBUTE_FIRE,POS_FACEUP,1-tp)
           and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_GRAVE)
end

-- ② 처리: 토큰을 상대 필드에 특수 소환 후 자신도 특수 소환
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 
       and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_BOMB,0,TYPES_TOKEN,1000,1000,1,RACE_PYRO,ATTRIBUTE_FIRE,POS_FACEUP,1-tp) then
        local token=Duel.CreateToken(tp,TOKEN_BOMB)
        Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP)
    end
    if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end
