--Blizzard Princess's Summons
local s,id=GetID()
function s.initial_effect(c)
	--Activate (① 덱에서 서치)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--② 묘지 효과: 블리자드 프린세스 공격시 상대 몬스터 효과 봉인
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost) -- 묘지에서 제외
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

--① 덱에서 "블리자드 프린세스" 몬스터 서치
function s.thfilter(c)
	return ((c:IsSetCard(0x757) and c:IsType(TYPE_MONSTER)) or c:IsCode(28348537))
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

--② 묘지 제외 효과
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	-- 공격 중인 "블리자드 프린세스" 몬스터가 있는 경우, 상대는 몬스터 효과 발동 불가
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetValue(function(e,re,tp)
		return re:IsActiveType(TYPE_MONSTER)
	end)
	e1:SetCondition(s.actcon)
	e1:SetReset(RESET_PHASE+PHASE_DAMAGE_CAL)
	Duel.RegisterEffect(e1,tp)
end
function s.actcon(e)
	local tc=Duel.GetAttacker()
	return tc and ((tc:IsSetCard(0x757) and tc:IsType(TYPE_MONSTER)) or tc:IsCode(28348537))
		and tc:IsControler(e:GetHandlerPlayer())
end
