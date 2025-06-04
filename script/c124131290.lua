--스완송 아술
local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon (Water Level 7 x2+)
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WATER),7,2,nil,nil,Xyz.InfiniteMats) -- true = min 2, max ∞
    c:EnableReviveLimit()

    --①: 공격 선언 시 필드 1장 파괴 (1턴 1번)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_ATTACK_ANNOUNCE)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    --②: 특정 소재 보유 시 추가 공격 부여
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetCondition(s.atkcon)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)
end

--①: 필드의 카드 1장 파괴
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() end
    if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end

--② 조건: 레벨 2 물 속성 소재 포함 시
function s.atkcon(e)
    local c=e:GetHandler()
    local mg=c:GetMaterial()
    return mg:IsExists(s.matfilter,1,nil)
end
function s.matfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsLevel(2)
end

--② 효과값: 이 카드의 소재 수 만큼 추가 공격 가능
function s.atkval(e,c)
    return c:GetOverlayCount()
end