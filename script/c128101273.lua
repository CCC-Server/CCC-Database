--Synchro Overlord
local s,id=GetID()
local SET_SYNCHRON=0x1017
local TOKEN_ID=62125439 -- Synchron Token ID

function s.initial_effect(c)
    -- 싱크로 소환 조건: 튜너 + 튜너 이외의 몬스터 1장 이상
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)

    ---------------------------------------------------------------
    -- ①: 싱크로 소환 성공 시, "Synchron Token" 1장 특수 소환
    ---------------------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.tkcon)
    e1:SetTarget(s.tktg)
    e1:SetOperation(s.tkop)
    c:RegisterEffect(e1)

    ---------------------------------------------------------------
    -- ②: 상대 효과 발동 시, 필드 카드 1장 파괴 (소재 수 만큼 사용 가능)
    ---------------------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.descon)
    e2:SetCost(s.descost)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)

    ---------------------------------------------------------------
    -- ③: 싱크로 소재 수 저장
    ---------------------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) end)
    e3:SetOperation(s.store_material_count)
    c:RegisterEffect(e3)
end

---------------------------------------------------------------
-- ① Synchron Token 특수 소환
---------------------------------------------------------------
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ID,SET_SYNCHRON,TYPES_TOKEN,1000,0,2,RACE_MACHINE,ATTRIBUTE_EARTH)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ID,SET_SYNCHRON,TYPES_TOKEN,1000,0,2,RACE_MACHINE,ATTRIBUTE_EARTH) then
        local token=Duel.CreateToken(tp,TOKEN_ID)
        Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
    end
end

---------------------------------------------------------------
-- ② 상대 효과 발동 시 필드 카드 파괴 (사용 가능 횟수 = 소재 수)
---------------------------------------------------------------
function s.store_material_count(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=c:GetMaterialCount()
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,ct)
    c:SetHint(CHINT_NUMBER,ct)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp
end

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local count=c:GetFlagEffect(id)
    if chk==0 then return count > 0 end
    -- 1개 소모
    c:ResetFlagEffect(id)
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,count - 1)
    c:SetHint(CHINT_NUMBER,count - 1)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() end
    if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end
