--Over Limit - Full Throttle
local s,id=GetID()
function s.initial_effect(c)
    --①: This card's name becomes "Limiter Removal" while on the field or in the GY.
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetValue(23171610) -- "Limiter Removal"
    c:RegisterEffect(e1)

    --②: Target 1 "Over Limit" monster on the field; double its ATK.
    --    Destroy it during the End Phase of this turn.
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetTarget(s.target)
    e2:SetOperation(s.activate)
    c:RegisterEffect(e2)
end

-- 카드군 / 이름 지정
-- "Limiter Removal"
s.listed_names={23171610}
-- "Over Limit" 카드군
s.listed_series={0xc48}

-- "Over Limit" 몬스터 타깃 필터
function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0xc48) and c:IsType(TYPE_MONSTER)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then 
        return chkc:IsOnField() and s.filter(chkc)
    end
    if chk==0 then
        return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local atk=tc:GetAttack()
        if atk<0 then atk=0 end
        -- ATK를 현재 ATK의 2배로
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK_FINAL)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        e1:SetValue(atk*2)
        tc:RegisterEffect(e1)
        -- 엔드 페이즈에 자괴
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e2:SetCode(EVENT_PHASE+PHASE_END)
        e2:SetRange(LOCATION_MZONE)
        e2:SetCountLimit(1)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        e2:SetOperation(s.desop)
        tc:RegisterEffect(e2)
    end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end
