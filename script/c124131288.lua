--스완송 시엘로
local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon (Water Level 5 x2)
    Xyz.AddProcedure(c,nil,5,2)
    c:EnableReviveLimit()

    --①: 세트된 카드 전부 파괴 (Xyz 소재 1장 제거)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.descost)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    --②: 레벨 2 물 속성 소재가 있을 경우 → 배틀 페이즈 중 마/함 효과 무효
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetCondition(s.immcon)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)
end

--① 비용: 소재 1장 제거
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
    c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

--① 대상: 상대 필드 세트된 카드 전부
function s.desfilter(c)
    return c:IsFacedown()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
    if chk==0 then return #g>0 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

--② 조건: 레벨 2 물 속성 몬스터가 소재로 있을 것 + 자신의 배틀 페이즈
function s.immcon(e)
    local c=e:GetHandler()
    if not Duel.IsBattlePhase() or Duel.GetTurnPlayer()~=c:GetControler() then return false end
    local mg=c:GetMaterial()
    return mg:IsExists(s.matfilter,1,nil)
end
function s.matfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsLevel(2)
end

--② 효과 무효 대상: 상대 마법 / 함정 효과
function s.efilter(e,te)
    return te:IsActiveType(TYPE_SPELL+TYPE_TRAP) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end