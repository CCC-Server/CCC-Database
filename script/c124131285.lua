--스완송 아쏠
local s,id=GetID()
function s.initial_effect(c)
    --①: 패/필드에서 자신 필드의 물 속성 엑시즈에게 소재로 들어감 (Quick Effect)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e1:SetTarget(s.xmtg)
    e1:SetOperation(s.xmop)
    c:RegisterEffect(e1)

    --②: 소재 효과 - 전투 후 상대 몬스터 제외
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DAMAGE_STEP_END)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.rmcon)
    e2:SetTarget(s.rmtg)
    e2:SetOperation(s.rmop)
    c:RegisterEffect(e2)
end

--①: 대상 선택 - 물 속성 엑시즈 몬스터
function s.xmfilter(c)
    return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_XYZ)
end
function s.xmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.xmfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.xmfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.xmfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.xmop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) then
        Duel.Overlay(tc,c)
    end
end

--②: 전투 후 제외 효과
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetOwner()
    local bc=rc:GetBattleTarget()
    return rc:IsAttribute(ATTRIBUTE_WATER) and rc:IsType(TYPE_XYZ) and bc and bc:IsRelateToBattle()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local rc=e:GetOwner()
    local bc=rc:GetBattleTarget()
    if chk==0 then return bc and bc:IsRelateToBattle() and bc:IsAbleToRemove() end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetOwner()
    local bc=rc:GetBattleTarget()
    if bc and bc:IsRelateToBattle() then
        Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)
    end
end