--메가록 데블
local s,id=GetID()
function c128220164.initial_effect(c)
-- 덱에서 특수 소환 불가
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- ①: 필드의 앞면 몬스터 2장을 뒷면으로 하고 패에서 특수 소환
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_POSITION)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ②: 프리 체인으로 자신 암석족을 뒤집고 덱에서 지속 마/함 세팅
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
    e2:SetCountLimit(1, id + 100)
    e2:SetTarget(s.setptg)
    e2:SetOperation(s.setpop)
    c:RegisterEffect(e2)

    -- ③: 필드의 몬스터가 리버스했을 경우 상대 몬스터 무효화
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_DISABLE)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_FLIP)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e3:SetTarget(s.distg)
    e3:SetOperation(s.disop)
    c:RegisterEffect(e3)
end

-- 덱 특소 불가
function s.splimit(e, se, sp, st)
    return not (st & SUMMON_TYPE_SPECIAL == SUMMON_TYPE_SPECIAL and se:GetHandler():IsLocation(LOCATION_DECK))
end

-- ① 특수 소환 효과
function s.spfilter(c)
    return c:IsFaceup() and c:IsCanTurnSet()
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return false end
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false)
            and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_MZONE, 0, 1, nil)
            and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 2, nil)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEDOWN)
    local g1 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEDOWN)
    local g2 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, g1:GetFirst())
    g1:Merge(g2)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_POSITION, g1, 2, 0, 0)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetTargetCards(e)
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        if #g > 0 then
            Duel.ChangePosition(g, POS_FACEDOWN_DEFENSE)
        end
    end
end

-- ② 지속 마/함 세팅 효과
function s.setpfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_ROCK) and c:IsCanTurnSet()
end
function s.stfilter(c, tp)
    return c:IsSetCard(0xc28) and c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS)
        and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end
function s.setptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.setpfilter(chkc) end
    if chk == 0 then
        return Duel.IsExistingTarget(s.setpfilter, tp, LOCATION_MZONE, 0, 1, nil)
            and Duel.IsExistingMatchingCard(s.stfilter, tp, LOCATION_DECK, 0, 1, nil, tp)
            and Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEDOWN)
    local g = Duel.SelectTarget(tp, s.setpfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_POSITION, g, 1, 0, 0)
end
function s.setpop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and Duel.ChangePosition(tc, POS_FACEDOWN_DEFENSE) > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
        local g = Duel.SelectMatchingCard(tp, s.stfilter, tp, LOCATION_DECK, 0, 1, 1, nil, tp)
        local sc = g:GetFirst()
        if sc then
            Duel.MoveToField(sc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
        end
    end
end

-- ③ 리버스 시 상대 효과 무효
function s.disfilter(c)
	return c:IsNegatableMonster() and c:IsType(TYPE_EFFECT)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.disfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_MZONE)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local tc=Duel.SelectMatchingCard(tp,s.disfilter,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
	if tc then
		Duel.HintSelection(tc,true)
		--Negate its effects until the end of this turn
		tc:NegateEffects(e:GetHandler(),RESET_PHASE|PHASE_END)
	end
end