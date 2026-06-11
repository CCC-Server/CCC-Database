--비르투스 코페르팀파니
local s,id=GetID()
function c128220186.initial_effect(c)
c:EnableReviveLimit()
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),2,99)

    -- ①: 서로의 드로우 페이즈에 1장 드로우
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_PREDRAW)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.drwtg)
    e1:SetOperation(s.drwop)
    c:RegisterEffect(e1)
    
    -- ②: 자신 필드의 "비르투스" 몬스터는 메인 페이즈 동안 대상 지정 내성
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.con)
    e2:SetTargetRange(LOCATION_MZONE, 0)
    e2:SetTarget(s.tgtg)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
    
    -- ③: 서로의 배틀 페이즈에 바운스 및 부가 효과
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SPECIAL_SUMMON + CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMING_BATTLE_START|TIMING_BATTLE_END)
    e3:SetCountLimit(1, {id, 1})
    e3:SetTarget(s.target)
    e3:SetOperation(s.operation)
    c:RegisterEffect(e3)
end

-- 카드군 코드 체크 ("비르투스")
s.listed_series = { 0xc29 }

-- ① 드로우 효과 타겟/오퍼레이션
function s.drwtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsPlayerCanDraw(tp, 1) end
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.drwop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Draw(tp, 1, REASON_EFFECT)
end

-- ② 메인 페이즈 조건 (MAIN1 혹은 MAIN2일 때)
function s.con(e)
    local ph = Duel.GetCurrentPhase()
    return ph == PHASE_MAIN1 or ph == PHASE_MAIN2
end

-- ② 대상 지정 내성 타겟 조건 (비르투스 몬스터)
function s.tgtg(e, c)
    return c:IsSetCard(0xc29) and c:IsMonster()
end

function s.get_magician_count(tp)
    return Duel.GetMatchingGroupCount(Card.IsFaceup, tp, LOCATION_MZONE, 0, nil, c:IsRace(RACE_SPELLCASTER))
end
function s.cfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)
end

-- 2. 대상 지정 (Target)
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk==0 then 
        local count = Duel.GetMatchingGroupCount(s.cfilter, tp, LOCATION_MZONE, 0, nil)
        return count > 0 and Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil) 
    end
    
    local count = Duel.GetMatchingGroupCount(s.cfilter, tp, LOCATION_MZONE, 0, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RTOHAND)
    -- 1장부터 마법사족의 수(count)까지 선택
    local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, count, nil)
    
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, #g, 0, 0)
end

-- 3. 효과 처리 (Operation)
function s.operation(e, tp, eg, ep, ev, re, r, rp)
    -- 대상 카드 중 필드에 앞면으로 남아있는 카드만 가져옴
    local tg = Duel.GetTargetCards(e)
    if #tg > 0 then
        local count = Duel.SendtoHand(tg, nil, REASON_EFFECT)
        -- 실제로 1장이라도 패로 되돌아갔다면 후속 효과 실행 (그 후, ~할 수 있다)
        if count > 0 then
            -- 묘지에 특수 소환 가능한 마법사족이 있는지 확인
            local CheckRace = Card.IsRace or Card.IsMonsterRace
            local sp_check = Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 
                             and Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_GRAVE, 0, 1, nil, e, 0, tp, false, false)
            
            -- 플레이어에게 추가 효과를 발동할지 물어봄 (Yes/No 공통 다이얼로그)
            if sp_check and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
                Duel.BreakEffect() -- "그 후" 처리를 위한 타이밍 분리 (동시 처리 아님)
                
                -- ● 묘지에서 마법사족 특수 소환
                Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
                local sg = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(Card.IsCanBeSpecialSummoned), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, 0, tp, false, false)
                
                if #sg > 0 and Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP) > 0 then
                    -- ● 자신 필드의 모든 몬스터의 공격력을 500 올린다
                    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, 0, nil)
                    for tc in aux.Next(g) do
                        local e1 = Effect.CreateEffect(e:GetHandler())
                        e1:SetType(EFFECT_TYPE_SINGLE)
                        e1:SetCode(EFFECT_UPDATE_ATTACK)
                        e1:SetValue(500)
                        e1:SetReset(RESET_EVENT + RESETS_STANDARD) -- 필드 벗어날 때까지 영구 지속
                        tc:RegisterEffect(e1)
                    end
                end
            end
        end
    end
	end