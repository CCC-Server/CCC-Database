--파이고라 그란즈
local s,id=GetID()
function s.initial_effect(c)
	--①: 자신 / 상대의 메인 페이즈에 발동할 수 있다. 필드의 이 카드를 포함하는, 자신의 패 / 필드의 몬스터를 융합 소재로 하고, 암석족 융합 몬스터 1장을 융합 소환한다. 그 후, 필드의 몬스터 1장의 표시 형식을 변경할 수 있다.
	local params = {aux.FilterBoolFunction(Card.IsRace,RACE_ROCK),nil,nil,nil,Fusion.ForcedHandler,s.op1}
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.con1)
	e1:SetTarget(Fusion.SummonEffTG(table.unpack(params)))
	e1:SetOperation(Fusion.SummonEffOP(table.unpack(params)))
	c:RegisterEffect(e1)
	--자신의 메인 페이즈에 발동할 수 있다. 이 카드의 표시 형식에 따라 이하의 효과를 적용한다.
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCountLimit(1,{id,1})
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
--effect 1
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

function s.op1(e,tc,tp,sg,chk)
	local c=e:GetHandler()
	if chk==1 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
		local g=Duel.SelectMatchingCard(tp,Card.IsCanChangePosition,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		if #g==0 then return end
		Duel.HintSelection(g,true)
		Duel.BreakEffect()
		Duel.ChangePosition(g,POS_FACEUP_DEFENSE,0,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)
	end
end

function s.tg2filter(c)
	return c:IsSetCard(0x822) and c:IsAbleToHand() 
end


function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.tg2filter,tp,LOCATION_DECK,0,nil)
	if chk==0 then return true end
	if e:GetHandler():IsAttackPos() then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,tp,LOCATION_DECK)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.tg2filter,tp,LOCATION_DECK,0,nil)
	local e1=Effect.CreateEffect(e:GetHandler())
	if not c:IsRelateToEffect(e) then return end
	if c:IsDefensePos() then
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetTarget(s.target2)
		e1:SetReset(RESET_PHASE+PHASE_END)
		e1:SetValue(1)
		Duel.RegisterEffect(e1,tp)
	elseif c:IsPosition(POS_FACEUP_ATTACK) then
		--Gain and reduce ATK when battling
		local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_ATOHAND)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end
function s.target2(e,c)
	return c:IsRace(RACE_ROCK)
end
