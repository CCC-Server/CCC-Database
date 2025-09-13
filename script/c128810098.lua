--올마이티 셀레스티얼 타이탄-원더 크로스 이터니티
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --싱크로 소환 절차 (천사족 싱크로 튜너 1 + 천사족 싱크로 비튜너 2+)
    Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(s.matfilter),1,1,Synchro.NonTunerEx(s.matfilter),2,99)
    --싱크로 소환으로만 소환 가능
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.synlimit)
    c:RegisterEffect(e0)

    -- material count 체크 (싱크로 소환시 사용된 '싱크로' 몬스터 수를 e6/e7에 전달)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_MATERIAL_CHECK)
    e1:SetValue(s.valcheck)
    c:RegisterEffect(e1)

    -- ATK/DEF 증가 (①)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e3)

    -- ② 효과 내성
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e4:SetValue(1)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e5:SetValue(aux.tgoval)
    c:RegisterEffect(e5)

    -- ③ 상대 몬스터가 공격 표시로 소환될 때(동시 소환된 전부 처리)
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,0))
    e6:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_SUMMON_SUCCESS)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.atkcon)
    e6:SetTarget(s.atktg)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)

    local e7=e6:Clone()
    e7:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e7)

    -- material count 라벨 전달용 (emc -> {e6,e7})
    emc:SetLabelObject({e6,e7})

    -- (선택) 카드 텍스트의 '1턴에 1번' 특수 소환 제한은 소환 효과 쪽에 SetCountLimit을 추가하세요.
end

s.listed_series={0xc02}
s.synchro_tuner_required=1
s.synchro_nt_required=2

-- 소재 조건: 천사족이면서 싱크로
function s.matfilter(c,scard,sumtype,tp)
    return c:IsRace(RACE_FAIRY,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

-- ① ATK/DEF 계산: 필드/묘지/제외는 Race만, Extra는 앞면(공개)만
function s.atkval(e,c)
    local tp=c:GetControler()
    local cnt1=Duel.GetMatchingGroupCount(Card.IsRace,tp,LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,RACE_FAIRY)
    local cnt2=Duel.GetMatchingGroupCount(function(tc) return tc:IsRace(RACE_FAIRY) and tc:IsFaceup() end,tp,LOCATION_EXTRA,0,nil)
    return (cnt1 + cnt2) * 300
end

-- material 체크: 사용한 'TYPE_SYNCHRO' 몬스터 수를 e6,e7에 전달
function s.valcheck(e,c)
    local ct=c:GetMaterial():FilterCount(Card.IsType,nil,TYPE_SYNCHRO)
    local objs=e:GetLabelObject()
    if type(objs)=="table" then
        for _,eff in ipairs(objs) do
            if eff and eff.SetLabel then
                eff:SetLabel(ct)
            end
        end
    else
        if objs and objs.SetLabel then
            objs:SetLabel(ct)
        end
    end
end

-- ③ 조건: 상대가 공격 표시 몬스터 소환
function s.posfilter(c,tp)
    return c:IsControler(1-tp) and c:IsPosition(POS_FACEUP_ATTACK)
end
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return not eg:IsContains(e:GetHandler()) and eg:IsExists(s.posfilter,1,nil,tp)
end

-- ③ 타겟 지정: 소환된 공격 표시 몬스터 전부를 타겟으로 등록
-- 또한 발동 횟수 제한 체크(발동한 횟수 < 소재 수)
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ct=e:GetLabel() or 0
    if chk==0 then
        return c:IsRelateToEffect(e) and ct>0 and c:GetFlagEffect(id) < ct and eg:IsExists(s.posfilter,1,nil,tp)
    end
    local tg=eg:Filter(s.posfilter,nil,tp)
    Duel.SetTargetCard(tg)
    -- 발동 카운트 증가 (이 발동을 1회 사용한 것으로 카운트)
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

-- ③ 처리: 대상 전부에 대해 ATK 감소 적용, 0이면 파괴
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=e:GetLabel() or 0
    if ct<=0 then return end
    local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    if not tg then return end
    local g=tg:Filter(Card.IsFaceup,nil)
    if #g==0 then return end
    local dg=Group.CreateGroup()
    for tc in aux.Next(g) do
        if tc:IsRelateToEffect(e) and tc:IsFaceup() then
            local preatk=tc:GetAttack()
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(ct * (-700))
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
            Duel.AdjustInstantly(tc)
            if preatk>0 and tc:GetAttack()==0 then dg:AddCard(tc) end
        end
    end
    if #dg>0 then
        Duel.BreakEffect()
        Duel.Destroy(dg,REASON_EFFECT)
    end
end
