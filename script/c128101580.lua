--스타토치 아카데미 의식 몬스터
local s,id=GetID()
local SET_STAR_TORCH=0xc57

function s.initial_effect(c)
    c:EnableReviveLimit()

  

    -------------------------------------------------
    --① 특수 소환 성공 시 상대 필드 전부 파괴
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.descon)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    -------------------------------------------------
    --② 몬스터 효과 체인 시 의식 소환
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.ritcon)
    e2:SetTarget(s.rittg)
    e2:SetOperation(s.ritop)
    c:RegisterEffect(e2)

    -------------------------------------------------
    --③ 대상 내성 (자기 필드 의식 몬스터)
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.tgfilter)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)
end

-------------------------------------------------
--①
-------------------------------------------------
function s.descon(e)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
    local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
    Duel.Destroy(g,REASON_EFFECT)
end

-------------------------------------------------
--②
-------------------------------------------------
function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
end

function s.thfilter(c)
    return c:IsSetCard(SET_STAR_TORCH) and c:IsType(TYPE_RITUAL) and c:IsAbleToHand()
end

function s.ritfilter(c,e,tp)
    return c:IsSetCard(SET_STAR_TORCH) and c:IsType(TYPE_RITUAL)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA,0,1,nil)
            and Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp)
    end
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
    --① 회수
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA,0,1,1,nil)
    if #g==0 then return end
    if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
    Duel.ConfirmCards(1-tp,g)

    --② 의식 몬스터 선택
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local rg=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp)
    local rc=rg:GetFirst()
    if not rc then return end

    local lv=rc:GetLevel()

    --③ 릴리스 그룹 선택 (레벨 합 체크 포함)
    local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_MZONE,LOCATION_MZONE,nil)

    local sg=mg:SelectWithSumGreater(tp,Card.GetLevel,lv)
    if not sg then return end

    Duel.Release(sg,REASON_EFFECT)

    --④ 의식 소환
    Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
    rc:CompleteProcedure()
end

-------------------------------------------------
--③
-------------------------------------------------
function s.tgfilter(e,c)
    return c:IsType(TYPE_RITUAL)
end