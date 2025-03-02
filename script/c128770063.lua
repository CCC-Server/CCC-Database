-- U.K 카드 예제
local s, id = GetID()
function s.initial_effect(c)
	-- ① 덱에서 "U.K" 몬스터 서치/특수 소환
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.thspcon)
	e1:SetTarget(s.thsptg)
	e1:SetOperation(s.thspop)
	c:RegisterEffect(e1)

	-- ② 릴리스되었을 경우 효과 발동 제한
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_RELEASE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1, {id, 1})
	e2:SetOperation(s.eflimop)
	c:RegisterEffect(e2)

	-- ③ 묘지에서 제외하고 일반 소환 실행
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1, {id, 2})
	e3:SetCondition(s.nscon)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.nstg)
	e3:SetOperation(s.nsop)
	c:RegisterEffect(e3)
end

-- 상대 필드에 몬스터가 존재할 때 조건
function s.thspcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_MZONE, 1, nil)
end


-- 덱에서 "U.K" 몬스터를 서치/특수 소환
function s.thspfilter(c,e,tp)
	return c:IsLevel(4) and c:IsSetCard(0x42d)
		and (c:IsAbleToHand() or (c:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0))
end

function s.thsptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.thspfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end
function s.thspop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local g=Duel.SelectMatchingCard(tp,s.thspfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then
		Duel.Hint(HINT_MESSAGE,tp,"No valid card was selected.")
		return
	end
	-- 카드가 핸드에 추가 가능한 경우
	if tc:IsAbleToHand() and (not tc:IsCanBeSpecialSummoned(e,0,tp,false,false) or Duel.SelectYesNo(tp,aux.Stringid(id,3))) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	-- 카드가 특수 소환 가능한 경우
	elseif tc:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- 릴리스된 경우 효과 발동 제한 적용
function s.eflimop(e, tp, eg, ep, ev, re, r, rp)
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0, 1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)
end

function s.aclimit(e, re, tp)
	return re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSetCard(0x42d)
end

-- 묘지에서 제외하고 일반 소환 실행
function s.nscon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
end

function s.nstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.nsfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, nil, 1, 0, 0)
end

function s.nsfilter(c)
	return c:IsSetCard(0x42d) and c:IsSummonable(true, nil)
end

function s.nsop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SUMMON)
	local g = Duel.SelectMatchingCard(tp, s.nsfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil)
	if #g > 0 then
		Duel.Summon(tp, g:GetFirst(), true, nil)
	end
end
