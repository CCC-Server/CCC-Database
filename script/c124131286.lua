--스완송 시니
local s,id=GetID()
function s.initial_effect(c)
    --①: 대상 몬스터 레벨 변경 + 특수 소환 제한
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_LVCHANGE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(2,id) -- 1턴에 2번까지
    e1:SetTarget(s.lvtg)
    e1:SetOperation(s.lvop)
    c:RegisterEffect(e1)

    --②: 소재로 있는 경우 - 전투/효과로 파괴되지 않음
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_XMATERIAL)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetCondition(s.indcon)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e3)
end

--①: 대상 선택 및 레벨 선언
function s.lvfilter(c)
    return c:IsFaceup() and c:IsLevelAbove(1)
end
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.lvfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.lvfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsFaceup() or not tc:IsRelateToEffect(e) then return end

    -- 레벨 선언
    Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
    local lv=Duel.AnnounceLevel(tp,2,7)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CHANGE_LEVEL)
    e1:SetValue(lv)
    e1:SetReset(RESETS_STANDARD_DISABLE_PHASE_END)
    tc:RegisterEffect(e1)

    -- 이 턴 동안 물 속성 엑시즈 몬스터만 특수 소환 가능
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e2:SetTargetRange(1,0)
    e2:SetTarget(s.splimit)
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not (c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_XYZ))
end

--②: 소재 효과 - 전투/효과 파괴 무효
function s.indcon(e)
    local rc=e:GetOwner()
    return rc:IsAttribute(ATTRIBUTE_WATER) and rc:IsType(TYPE_XYZ)
end