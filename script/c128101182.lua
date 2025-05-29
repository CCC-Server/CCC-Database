--Cybernetic Link Supporter
local s,id=GetID()
function s.initial_effect(c)
    -- 링크 소환 조건
    Link.AddProcedure(c,s.matfilter,1,1)
    c:EnableReviveLimit()

    --①: 링크 소환 성공 시 "Cyber" 또는 "Cybernetic" Spell/Trap 서치
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --②: Cyber 기계족 융합 몬스터 파괴 대체
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
end

-- 🔹 링크 소재: 링크 몬스터 이외의 Cyber 몬스터 1장
function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(0x1093) and not c:IsType(TYPE_LINK)
end

-- 🔸 ①: 링크 소환 성공 시
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP)
        and (c:IsSetCard(SET_CYBER) or c:IsSetCard(SET_CYBERNETIC)) -- 0x1093 = Cyber, 0x1F = Cybernetic
        and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- 🔸 ②: Cyber 기계족 융합 몬스터 파괴 대체
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsOnField()
        and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION)
        and c:IsSetCard(SET_CYBER) -- Cyber
        and c:IsReason(REASON_EFFECT+REASON_BATTLE)
        and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp)
        and e:GetHandler():IsAbleToRemove() end
    return Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,1))
end

function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end
