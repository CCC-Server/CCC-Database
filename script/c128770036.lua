-- M.A-양 스크립트 (링크 3)
local s, id = GetID()
function s.initial_effect(c)
	-- 링크 소환
	Link.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), 2)
	c:EnableReviveLimit()

	-- 효과 1: 싱크로 소환 후 패로 되돌리기
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 효과 2: 융합 소환
	local params = {
		fusfilter = aux.FilterBoolFunction(Card.IsSetCard, 0x30d),
		matfilter = aux.FALSE,
		extrafil = s.fextra,
		extraop = Fusion.ShuffleMaterial,
		extratg = s.extratarget
	}
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, { id, 1 })
	e2:SetCost(s.spcost)
	e2:SetTarget(Fusion.SummonEffTG(params))
	e2:SetOperation(Fusion.SummonEffOP(params))
	c:RegisterEffect(e2)
end

-- 싱크로 소환 후 패로 되돌리기 효과 조건
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(Card.IsType, 1, nil, TYPE_SYNCHRO) and eg:IsExists(Card.IsSetCard, 1, nil, 0x30d)
end

-- 패로 되돌릴 대상 선택
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsAbleToHand() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToHand, tp, LOCATION_MZONE, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RTOHAND)
	local g = Duel.SelectTarget(tp, Card.IsAbleToHand, tp, LOCATION_MZONE, 0, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end

-- 패로 되돌리기 효과 실행
function s.thop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc, nil, REASON_EFFECT)
	end
end

-- 융합 소환 효과의 비용
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.CheckLPCost(tp, 1000) end
	Duel.PayLPCost(tp, 1000)
end

-- 융합 소환용 추가 소재 설정
function s.fextra(e, tp, mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(aux.NecroValleyFilter(Card.IsFaceup, Card.IsAbleToDeck)), tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, nil)
end

-- 융합 소환용 추가 대상 설정
function s.extratarget(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 0, tp, LOCATION_GRAVE + LOCATION_REMOVED)
end
