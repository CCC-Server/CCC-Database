--스완송 미르
local s,id=GetID()
function s.initial_effect(c)
    -- ①: 소환 성공 시 "바다" 서치
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    -- ②: 이 카드를 소재로 한 물 속성 엑시즈 몬스터 강화
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_XMATERIAL)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetCondition(s.atkcon)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)
end

--덱에서 "바다"를 서치
function s.thfilter(c)
    return c:IsCode(22702055) and c:IsAbleToHand()
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

--소재로 사용할 경우: 물 속성 엑시즈 몬스터 강화 조건
function s.atkcon(e)
    local c=e:GetHandler()
    local rc=e:GetOwner()
    return rc:IsAttribute(ATTRIBUTE_WATER) and rc:IsType(TYPE_XYZ)
end

--랭크 × 200 공격력 증가
function s.atkval(e,c)
    return c:GetRank()*200
end