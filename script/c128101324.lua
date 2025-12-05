--하이메타파이즈 갤럭시 씨 서펀트
--Hi-Metaphys Galaxy Sea Serpent
local s,id=GetID()
function s.initial_effect(c)
    --펜듈럼 소환 처리
    Pendulum.AddProcedure(c)
    --------------------------------
    --P효과 : 1턴에 1번, 덱에서 "메타파이즈" 몬스터 1장을 제외하고
    --덱/묘지에서 "메타파이즈" 필드 마법 1장을 세트
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE+CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCountLimit(1) --이 카드의 P존 효과는 필드에서 1번만 사용
    e1:SetCost(s.pzcost)
    e1:SetTarget(s.pztg)
    e1:SetOperation(s.pzop)
    c:RegisterEffect(e1)
end

--------------------------------
-- 코스트 : 덱에서 "메타파이즈" 몬스터 1장을 제외
--------------------------------
function s.costfilter(c)
    return c:IsSetCard(0x105) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost()
end
function s.pzcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

--------------------------------
-- 세트할 카드 필터 : "메타파이즈" 필드 마법
--------------------------------
function s.setfilter(c)
    return c:IsSetCard(0x105) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)
        and c:IsSSetable()  --세트 가능한 카드
end

function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        --세트할 공간과 세트 가능한 카드가 있는지 확인
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
end

function s.pzop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    --묘지 쪽은 네크로밸리 대응을 위해 필터를 감싼다
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),
        tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    local tc=g:GetFirst()
    if tc then
        --필드 마법 세트
        Duel.SSet(tp,tc)
        --필드 마법인 것을 보여주기 위해 상대에게 공개
        Duel.ConfirmCards(1-tp,tc)
    end
end
