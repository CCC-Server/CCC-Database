--스완송 바서
local s,id=GetID()
function s.initial_effect(c)
    --①: 패에서 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    --②: 엑시즈 몬스터에게 효과 내성 부여
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_XMATERIAL)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e2:SetCondition(s.immcon)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
end

--특수 소환 조건: 레벨 2 or 랭크 2 + 물 속성 몬스터 존재
function s.cfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER)
        and (c:IsLevel(2) or (c:IsType(TYPE_XYZ) and c:GetRank()==2))
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

--②: 이 카드를 소재로 사용한 물 속성 엑시즈 몬스터 효과 내성 부여
function s.immcon(e)
    local rc=e:GetOwner()
    return rc:IsAttribute(ATTRIBUTE_WATER) and rc:IsType(TYPE_XYZ)
end