--스완송 크리아이나
local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon (Water Level 7 x3+)
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WATER),7,3,nil,nil,Xyz.InfiniteMats)
    c:EnableReviveLimit()

    --①: 엑시즈 소환 성공 시 물 속성 이외의 몬스터 전부 파괴
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.descon)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    --②-1: 공격력 증가 (소재 수 × 500)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetCondition(s.atkcon)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    --②-2: 1턴에 1번, 효과 발동 무효 + 파괴
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

--①: 엑시즈 소환으로만 발동
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.desfilter(c)
    return not c:IsAttribute(ATTRIBUTE_WATER)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    if chk==0 then return #g>0 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    Duel.Destroy(g,REASON_EFFECT)
end

--② 조건 공통: 레벨 2 물 속성 소재를 포함할 경우
function s.matfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsLevel(2)
end
function s.has_lv2water(c)
    return c:GetMaterial():IsExists(s.matfilter,1,nil)
end

--②-1: 공격력 증가 조건 및 수치
function s.atkcon(e)
    return s.has_lv2water(e:GetHandler())
end
function s.atkval(e,c)
    return c:GetOverlayCount()*500
end

--②-2: 효과 무효 + 파괴 조건
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return s.has_lv2water(e:GetHandler()) and Duel.IsChainDisablable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
    local rc=re:GetHandler()
    if rc:IsRelateToEffect(re) then
        Duel.Destroy(rc,REASON_EFFECT)
    end
end