--종이 비행기 저지 (Paper Plane Counter)  ← 실제 카드명으로 바꿔 써도 됨
local s,id=GetID()
function s.initial_effect(c)
    -- 카드군
    s.listed_series={0xc53}

    --------------------------------
    -- ① 카운터: 발동 / 효과 무효 + 파괴
    --   선택적으로 "Paper Plane" 융합 몬스터를 릴리스해서
    --   해설 처리 시 GY의 비융합 "Paper Plane" 몬스터를 특소 가능
    --   (①·② 중 1개만, 1턴에 1번)
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCountLimit(1,id) -- ①·② 공유 하드 OPT
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    --------------------------------
    -- ② GY에서 세트
    --   유니온 몬스터가 특수 소환되면 GY에서 세트
    --   이 효과로 세트된 카드는 필드에서 떠날 때 제외
    --   (①·② 중 1개만, 1턴에 1번)
    --------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id) -- ①와 공유
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

--------------------------------------------------
-- 공통 필터
--------------------------------------------------
function s.ppmonfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER)
end

--------------------------------------------------
-- ① negate / destroy + (선택적) 특소
--------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    -- 자신 필드에 "Paper Plane" 몬스터를 컨트롤하고,
    -- 마법/함정 또는 몬스터 효과 발동일 때
    if not Duel.IsExistingMatchingCard(s.ppmonfilter,tp,LOCATION_MZONE,0,1,nil) then return false end
    if not Duel.IsChainNegatable(ev) then return false end
    return re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE)
end

-- 융합 PP를 릴리스할지 선택하는 코스트
function s.fusrelfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xc53)
        and c:IsType(TYPE_FUSION) and c:IsReleasable()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    -- label 0 = 릴리스 안 함, 1 = 릴리스함
    e:SetLabel(0)
    if chk==0 then return true end
    if Duel.IsExistingMatchingCard(s.fusrelfilter,tp,LOCATION_MZONE,0,1,nil)
        and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        e:SetLabel(1)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
        local g=Duel.SelectMatchingCard(tp,s.fusrelfilter,tp,LOCATION_MZONE,0,1,1,nil)
        if #g>0 then
            Duel.Release(g,REASON_COST)
        else
            e:SetLabel(0)
        end
    end
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0xc53)
        and not c:IsType(TYPE_FUSION)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsOnField() then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
    -- 릴리스해서 추가로 특소까지 노릴 수 있는지 정보만 올려둠 (필수 아님)
    if e:GetLabel()==1 then
        Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not Duel.NegateActivation(ev) then return end
    local rc=re:GetHandler()
    if rc:IsRelateToEffect(re) then
        Duel.Destroy(rc,REASON_EFFECT)
    end
    -- 융합 PP를 릴리스하고 발동했다면, 선택적으로 GY에서 비융합 PP 특소
    if e:GetLabel()==1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
        if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=g:Select(tp,1,1,nil)
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

--------------------------------------------------
-- ② GY에서 세트
--------------------------------------------------
function s.unionspfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_UNION)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    -- 유니온 몬스터가 어느 쪽 필드든 특수 소환되었을 때
    return eg:IsExists(s.unionspfilter,1,nil)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsSSetable() end
    Duel.SetOperationInfo(0,0,c,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.SSet(tp,c)>0 then
        -- 이 효과로 세트된 이 카드는 필드에서 나갈 때 제외
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
        e1:SetValue(LOCATION_REMOVED)
        c:RegisterEffect(e1)
    end
end
