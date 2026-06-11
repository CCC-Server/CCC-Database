--비르투스-프렐류드
local s,id=GetID()
function c128220190.initial_effect(c)
-- 필드 마법 발동 시 처리
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
   local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_COUNTER)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_FZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.ctcon)
    e1:SetTarget(s.cttg)
    e1:SetOperation(s.ctop)
    c:RegisterEffect(e1)

    -- 2: 메인 페이즈 효과
    local e2 = e1:Clone()
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCondition(s.ctmcon)
    c:RegisterEffect(e2)

    -- 3: 배틀 페이즈 효과
    local e3 = e1:Clone()
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCondition(s.ctbcon)
    c:RegisterEffect(e3)

    -- 4: 엔드 페이즈 효과
    local e4 = e1:Clone()
    e4:SetDescription(aux.Stringid(id, 3))
    e4:SetCondition(s.ctecon)
    c:RegisterEffect(e4)
    
    -- ②: 악장 카운터 수에 따른 효과
    -- ● 1개 이상: 파괴 대체 효과 (지속 효과)
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EFFECT_DESTROY_REPLACE)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCondition(s.repcon)
    e5:SetTarget(s.reptg)
    e5:SetValue(s.repval)
    e5:SetOperation(s.repop)
    c:RegisterEffect(e5)
    
    -- ● 3개 이상: 패를 1장 버리고 덱/묘지에서 "비르투스" 카드 서치 (기동 효과)
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 1))
    e6:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_FZONE)
    e6:SetCondition(s.thcon)
    e6:SetCost(s.thcost)
    e6:SetTarget(s.thtg)
    e6:SetOperation(s.thop)
    c:RegisterEffect(e6)
    
    -- ● 5개 이상: "비르투스" 몬스터 효과 발동에 체인 불가 (지속 효과)
    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e7:SetCode(EVENT_CHAINING)
    e7:SetRange(LOCATION_FZONE)
    e7:SetCondition(s.chcon)
    e7:SetOperation(s.chop)
    c:RegisterEffect(e7)
end

-- 카운터 식별자 설정 (악장 카운터: 임의로 0x1c29로 지정)
local COUNTER_MUSIC = 0x1c29

---------------------------------------------------------------------------------
-- ①번 효과: 카운터 적립

function s.ctcon(e, tp, eg, ep, ev, re, r, rp)
       return Duel.IsPhase(PHASE_STANDBY) and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
function s.ctmcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase() and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
function s.ctbcon(e, tp, eg, ep, ev, re, r, rp)
       return Duel.IsBattlePhase() and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
function s.ctecon(e, tp, eg, ep, ev, re, r, rp)
       return Duel.IsPhase(PHASE_END) and rp == tp and re:IsActiveType(TYPE_MONSTER)
end
-- 카운터 적치 타겟
function s.cttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanAddCounter(COUNTER_MUSIC, 1) end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, e:GetHandler(), 1, 0, COUNTER_MUSIC)
end

-- 카운터 적치 실행
function s.ctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:AddCounter(COUNTER_MUSIC, 1)
    end
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	--Destroy all monsters your opponent controls
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.ctecon)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

---------------------------------------------------------------------------------
-- ②번 효과 (●1개): 파괴 대체

function s.repcon(e, tp, eg, ep, ev, re, r, rp)
    -- 필드에 악장 카운터가 1개 이상 존재할 것
    return Duel.GetCounter(tp, 1, 1, COUNTER_MUSIC) >= 1
end

function s.repfilter(c, tp)
    -- 자신 필드의 카드가 전투/효과로 파괴되는지 확인
    return c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD)
        and c:IsReason(REASON_BATTLE + REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e, tp, eg, egp, ev, re, r, rp, chk)
    if chk == 0 then return eg:IsExists(s.repfilter, 1, nil, tp) end
    if Duel.SelectEffectYesNo(tp, e:GetHandler(), 96) then -- 96: 대체하시겠습니까?
        return true
    end
    return false
end

function s.repval(e, c)
    return s.repfilter(c, e:GetHandlerPlayer())
end

function s.repop(e, tp, eg, egp, ev, re, r, rp)
    -- 자신 필드(보통 이 카드 위)의 악장 카운터를 1개 제거
    Duel.RemoveCounter(tp, 1, 1, COUNTER_MUSIC, 1, REASON_EFFECT)
end

---------------------------------------------------------------------------------
-- ②번 효과 (●3개): "비르투스(0xc29)" 카드 서치/샐비지

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():GetCounter(COUNTER_MUSIC) >= 3
end

function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
end

function s.thfilter(c)
    return c:IsSetCard(0xc29) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

---------------------------------------------------------------------------------
-- ②번 효과 (●5개): "비르투스" 몬스터 효과 발동 시 상대 체인 불가

function s.chcon(e, tp, eg, ep, ev, re, r, rp)
    -- 필드에 악장 카운터가 5개 이상 존재할 것
    return e:GetHandler():GetCounter(COUNTER_MUSIC) >= 5
end

function s.chop(e, tp, eg, ep, ev, re, r, rp)
    -- 발동한 효과가 자신 필드/패/묘지 등의 "비르투스(0xc29)" 카드군 '몬스터'의 효과일 때
    if rp == tp and re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSetCard(0xc29) then
        -- 상대는 마법/함정/몬스터의 효과를 발동할 수 없다.
        Duel.SetChainLimit(s.chainlm)
    end
end

function s.chainlm(e, rp, tp)
    return tp == rp
end