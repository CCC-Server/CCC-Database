--유네티스 서든 바이트
local s,id=GetID()
function s.initial_effect(c)
	--①: 상대 몬스터 1장과 자신 유네티스 카드 1장 바운스
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--②: 묘지 제외 후 효과 (턴에 따라 다름)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc80}

-- [효과 ①]
function s.thfilter(c)
	return c:IsSetCard(0xc80) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(s.thfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler()) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g1=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g2=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_ONFIELD,0,1,1,e:GetHandler())
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g1,2,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end

-- [효과 ②]
function s.sumfilter(c)
	return c:IsSetCard(0xc80) and c:IsSummonable(true,nil)
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	local turn_p=Duel.GetTurnPlayer()
	if chk==0 then
		if turn_p==tp then
			return true -- 자신 턴에는 소환권 부여 (실행 가능 여부와 무관하게 발동 가능)
		else
			-- 상대 턴에는 즉시 소환 가능한 몬스터가 있어야 함
			return Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
		end
	end
	if turn_p~=tp then
		Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
	end
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local turn_p=Duel.GetTurnPlayer()
	if turn_p==tp then
		-- 자신 턴: 일소권 추가
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
		e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
		e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xc80))
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	else
		-- 상대 턴: 일반 소환 실행
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local g=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil)
		if #g>0 then
			Duel.Summon(tp,g:GetFirst(),true,nil)
		end
	end
end