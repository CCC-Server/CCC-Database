--암군 페이탈러티 퓨전
local s,id=GetID()
function s.initial_effect(c)
	--패에서도 발동 가능(자신 필드에 융합 몬스터가 존재할 경우)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(function(e)
		return Duel.IsExistingMatchingCard(Card.IsType,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil,TYPE_FUSION)
	end)
	c:RegisterEffect(e0)

	--① 융합소환(어둠 속성) + 상대 몬스터 효과에 체인했다면 그 효과 무효
	-- Fusion helper를 그대로 사용
	local fustg=Fusion.SummonEffTG(aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK))
	local fusop=Fusion.SummonEffOP(aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK))
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_END_PHASE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	-- Target: 그대로 위임
	e1:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk)
		local res=fustg(e,tp,eg,ep,ev,re,r,rp,chk)
		-- 체인 대응 시(상대 몬스터 효과) 무효 정보 표시
		if re and rp==1-tp and re:IsActiveType(TYPE_MONSTER) then
			Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
			e:SetLabel(1)
		else
			e:SetLabel(0)
		end
		return res
	end)
	-- Operation: 먼저 융합 소환 실행 → 조건 맞으면 그 체인(ev) 무효
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		fusop(e,tp,eg,ep,ev,re,r,rp)
		if e:GetLabel()==1 and Duel.IsChainNegatable(ev) then
			Duel.NegateActivation(ev)
		end
	end)
	c:RegisterEffect(e1)

	--② GY에서 제외 → 대상 1장 덱맨밑으로 돌리고 드로우 1
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc45,SET_FUSION}

--② 되돌릴 대상:
--  - 자신의 묘지/제외의 "암군" 카드(이 카드 제외) 1장
--  - 또는 "Fusion" 테마의 일반 마법(SET_FUSION) / "Polymerization" 일반 마법 1장
function s.tdfilter(c)
	local isArmy = c:IsSetCard(0xc45) and not c:IsCode(id)
	local isFusionSpell = c:IsType(TYPE_SPELL) and c:IsType(TYPE_NORMAL)
		and (c:IsSetCard(SET_FUSION) or c:IsCode(CARD_POLYMERIZATION))
	return (isArmy or isFusionSpell) and c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and (chkc:IsLocation(LOCATION_GRAVE) or chkc:IsLocation(LOCATION_REMOVED))
			and s.tdfilter(chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoDeck(tc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
