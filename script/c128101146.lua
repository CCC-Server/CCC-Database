--Volcanic Forge Trigger
local s,id=GetID()
function s.initial_effect(c)
    -- 링크 소환 조건: 레벨 4 이하 볼캐닉 몬스터 1장
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,1,1)

    --①: 링크 소환 성공 시 볼캐닉 몬스터 서치
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --②: 묘지로 보내졌을 때 데미지 + 브레이즈 캐논 세트
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DAMAGE+CATEGORY_LEAVE_GRAVE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

s.listed_series={SET_VOLCANIC,SET_BLAZE_ACCELERATOR}
s.listed_names={id}

-- 링크 소재: 레벨 4 이하 볼캐닉 몬스터
function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(SET_VOLCANIC,lc,sumtype,tp) and c:IsLevelBelow(4)
end

-------------------------------------------------
--①: 링크 소환 성공 시 서치
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.thfilter(c)
    return c:IsSetCard(SET_VOLCANIC) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-------------------------------------------------
--②: 묘지로 보내졌을 때 효과
function s.setfilter(c)
    return c:IsSetCard(SET_BLAZE_ACCELERATOR) and (c:IsType(TYPE_CONTINUOUS) or c:IsType(TYPE_TRAP)) and not c:IsForbidden()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() and chkc:IsRace(RACE_PYRO) end
    if chk==0 then return Duel.IsExistingTarget(Card.IsRace,tp,LOCATION_MZONE,0,1,nil,RACE_PYRO)
        and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectTarget(tp,Card.IsRace,tp,LOCATION_MZONE,0,1,1,nil,RACE_PYRO)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,g:GetFirst():GetLevel()*100)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    local lv=tc:GetLevel()
    if lv>0 then
        Duel.Damage(1-tp,lv*100,REASON_EFFECT)
    end
    -- 세트 실행
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    local sc=sg:GetFirst()
    if sc then
        Duel.MoveToField(sc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end
