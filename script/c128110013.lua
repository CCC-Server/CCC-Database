--유네티스 인베이젼
local s,id=GetID()
function s.initial_effect(c)
	--①: 서치 및 상대 존 봉쇄
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--②: 묘지 효과 (릴리스 경감 + 세트)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc70}

-- [효과 ①: 서치 후 상대 존 2곳 봉쇄]
function s.thfilter(c)
	return c:IsSetCard(0xc70) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		
		-- 상대 필드의 빈 메인 몬스터 존 확인
		local available_zones = 0
		for i=0,4 do
			if Duel.GetFieldCard(1-tp, LOCATION_MZONE, i) == nil and Duel.CheckLocation(1-tp, LOCATION_MZONE, i) then
				available_zones = available_zones + 1
			end
		end
		
		if available_zones >= 2 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ZONE)
			-- 상대 메인 몬스터 존 2곳 선택
			local zone = Duel.SelectDisableField(tp, 2, 0, LOCATION_MZONE, 0)
			if zone~=0 then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetCode(EFFECT_DISABLE_FIELD)
				e1:SetOperation(function(e) return zone end)
				e1:SetReset(RESET_PHASE+PHASE_END, 2) -- 다음 턴 종료시까지
				Duel.RegisterEffect(e1,tp)
			end
		end
	end
end

-- [효과 ②: 릴리스 경감 적용 및 묘지 세트]
function s.cfilter(c,tp)
	return c:IsSetCard(0xc70) and c:IsSummonType(SUMMON_TYPE_NORMAL) and c:IsControler(tp)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	-- 이번 턴, "유네티스" 몬스터 일반 소환 시 릴리스 2개까지 경감 (레벨 5~8 몬스터 릴리스 없이 소환 가능)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DECREASE_TRIBUTE)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xc70))
	e1:SetValue(2)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp,c)
	end
end