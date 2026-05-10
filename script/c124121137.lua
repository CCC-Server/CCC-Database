-- 제너럴 마스터 데몬
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 자신 / 상대 스탠바이 페이즈 또는 엔드 페이즈에 500 LP 지불하고 패에서 특수 소환. 그 후 데몬 마/함 또는 팬더모니엄 서치/세트
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SET)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetHintTiming(TIMING_STANDBY_PHASE+TIMING_END_PHASE,TIMING_STANDBY_PHASE+TIMING_END_PHASE)
    e1:SetCondition(s.spcon)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ②: 몬스터 존의 이 카드는 공격할 수 없다 (지속 효과)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_ATTACK)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    c:RegisterEffect(e2)

    -- ②: 엔드 페이즈에 파괴된다 (지속 효과 - 체인을 만들지 않음)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EVENT_PHASE+PHASE_END)
    e3:SetCountLimit(1)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)

    -- ③: 효과로 파괴되었을 경우, 묘지/제외 상태의 다른 "데몬" 카드 1장을 패로 회수
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetCountLimit(1,{id,1})
    e4:SetCondition(s.thcon2)
    e4:SetTarget(s.thtg2)
    e4:SetOperation(s.thop2)
    c:RegisterEffect(e4)
end
s.listed_names={94585852,id}
s.listed_series={0x45}

-- ① 발동 조건
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return ph==PHASE_STANDBY or ph==PHASE_END
end

-- ① 코스트
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,500) end
    Duel.PayLPCost(tp,500)
end

-- ① 서치/세트 필터
function s.thfilter(c)
    return ((c:IsSetCard(0x45) and c:IsType(TYPE_SPELL+TYPE_TRAP)) or c:IsCode(94585852))
        and (c:IsAbleToHand() or c:IsSSetable())
end

-- ① 타겟
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ① 효과 처리 (ToHandOrElse 적용)
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local tc=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
        if not tc then return end
        
        aux.ToHandOrElse(tc,tp,
            Card.IsSSetable,
            function(c)
                Duel.SSet(tp,tc)
            end,
            aux.Stringid(id,3)
        )
    end
end

-- ② 엔드 페이즈 자괴 처리 (지속 효과용 Operation)
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end

-- ③ 샐비지 조건
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

-- ③ 샐비지 필터
function s.gyfilter(c)
    return c:IsSetCard(0x45) and not c:IsCode(id) and c:IsAbleToHand()
        and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

-- ③ 타겟
function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.gyfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.gyfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.gyfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

-- ③ 효과 처리
function s.thop2(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end