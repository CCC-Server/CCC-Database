--앰포리어스 네메시스
--Emporeus Nemesis
local s,id=GetID()
function s.initial_effect(c)
	--①: 효과 무효 & 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--②: 묘지에서 프리체인으로 링크 재소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)

	--③: 링크 4 이상 사이버스족이 있으면 패에서도 발동 가능
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e3:SetCondition(s.handcon)
	c:RegisterEffect(e3)
end
s.listed_series={0xc46}

--------------------------------------------------
--①: 필드 카드 1장 무효화 + 제외
--------------------------------------------------
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xc46),tp,LOCATION_MZONE,0,1,nil)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsOnField() and chkc:IsFaceup() and chkc:IsCanBeDisabled() and chkc:IsAbleToRemove()
	end
	if chk==0 then
		return Duel.IsExistingTarget(aux.AND(Card.IsFaceup,Card.IsCanBeDisabled,Card.IsAbleToRemove),tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,aux.AND(Card.IsFaceup,Card.IsCanBeDisabled,Card.IsAbleToRemove),tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	tc:NegateEffects(e:GetHandler())
	Duel.AdjustInstantly(tc)
	if tc:IsDisabled() and tc:IsAbleToRemove() then
		Duel.BreakEffect()
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

--------------------------------------------------
--②: 묘지 프리체인 → 링크 몬스터 되돌리고 재링크소환
--------------------------------------------------
function s.ssfilter(c,e,tp)
	return c:IsSetCard(0xc46) and c:IsType(TYPE_LINK)
		and (c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_GRAVE))
		and c:IsAbleToExtra()
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE)
			and s.ssfilter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.ssfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.ssfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local code=tc:GetOriginalCode()
	-- 엑스트라 덱으로 되돌림
	if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	Duel.BreakEffect()
	-- 동일 코드의 링크 몬스터 검색
	local g=Duel.GetMatchingGroup(function(sc)
		return sc:IsCode(code) and sc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
	end,tp,LOCATION_EXTRA,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=g:Select(tp,1,1,nil):GetFirst()
		if Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)>0 then
			sc:CompleteProcedure()
		end
	end
end

--------------------------------------------------
--③: 패에서 발동 가능
--------------------------------------------------
function s.handcon(e)
	return Duel.IsExistingMatchingCard(function(c)
		return c:IsFaceup() and c:IsRace(RACE_CYBERSE) and c:IsLinkAbove(4)
	end,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
