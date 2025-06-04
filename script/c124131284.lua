--스완송 블라우
local s,id=GetID()
function s.initial_effect(c)
    --①: 필드에 "바다"가 존재하면 패에서 특수 소환
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    --②: 소재 효과 - 전투 후 상대 몬스터 효과 무효
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DAMAGE_STEP_END)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.discon)
    e2:SetTarget(s.distg)
    e2:SetOperation(s.disop)
    c:RegisterEffect(e2)
end

--①: "바다"가 존재하면 패에서 특수 소환
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.IsEnvironment(22702055)
end

--②: 전투 후 효과 무효
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetOwner()
    if not (rc:IsAttribute(ATTRIBUTE_WATER) and rc:IsType(TYPE_XYZ)) then return false end
    local bc=rc:GetBattleTarget()
    return bc and bc:IsRelateToBattle()
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    local rc=e:GetOwner()
    local bc=rc:GetBattleTarget()
    if chk==0 then return bc and bc:IsRelateToBattle() and not bc:IsDisabled() end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,bc,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetOwner()
    local bc=rc:GetBattleTarget()
    if bc and bc:IsRelateToBattle() and not bc:IsDisabled() then
        -- 효과 무효화
        Duel.NegateRelatedChain(bc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(rc)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        bc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        bc:RegisterEffect(e2)
    end
end