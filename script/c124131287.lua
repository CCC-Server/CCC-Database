--스완송 바흐르
local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WATER),4,2) -- 레벨 4 몬스터 2장
    c:EnableReviveLimit()

    --①: 엑시즈 소환 성공 시 드로우
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.drcon)
    e1:SetTarget(s.drtg)
    e1:SetOperation(s.drop)
    c:RegisterEffect(e1)

    --②: 레벨 2 물 속성 소재가 있을 경우, 배틀 페이즈에 공격력 +2500
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetCondition(s.atkcon)
    e2:SetValue(2500)
    c:RegisterEffect(e2)
end

--① 드로우 조건: 엑시즈 소환으로 소환되었을 경우만
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Draw(tp,1,REASON_EFFECT)
end

--② 공격력 증가 조건: 레벨 2 물 속성 몬스터를 소재로 포함 + 배틀 페이즈
function s.atkcon(e)
    local c=e:GetHandler()
    local tp=c:GetControler()
    if Duel.GetCurrentPhase()<PHASE_BATTLE_START or Duel.GetCurrentPhase()>PHASE_BATTLE then
        return false
    end
    local mg=c:GetMaterial()
    return mg:IsExists(s.matfilter,1,nil)
end
function s.matfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsLevel(2)
end