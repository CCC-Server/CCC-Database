--스펠크래프트 식신 귀인
local s,id=GetID()
function s.initial_effect(c)
	--① 공격력 설정 : 이번 턴 파괴된 "식신" 몬스터 공격력 합계
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	--② 배틀 페이즈 중 마력 카운터 제거 후 공격력 상승 (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetHintTiming(TIMINGS_CHECK_MONSTER+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
	--③ 덱 서치 (패에서 발동)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,{id,3})
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

------------------------------------
--① 공격력 계산 : 이번 턴 파괴된 식신 몬스터 공격력 합계
------------------------------------
if not s.global_check then
	s.global_check=true
	s.destroyed_group=Group.CreateGroup()
	s.destroyed_group:KeepAlive()
	--필드에서 식신이 파괴될 때 기록
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge1:SetCode(EVENT_DESTROYED)
	ge1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		local g=eg:Filter(function(c)
			return c:IsSetCard(0x762) and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		end,nil)
		if #g>0 then
			for tc in aux.Next(g) do
				s.destroyed_group:AddCard(tc)
			end
		end
	end)
	Duel.RegisterEffect(ge1,0)
	--턴이 바뀔 때 초기화
	local ge2=Effect.GlobalEffect()
	ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
	ge2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		s.destroyed_group:Clear()
	end)
	Duel.RegisterEffect(ge2,0)
end

function s.atkval(e,c)
	local atk_sum=0
	for tc in aux.Next(s.destroyed_group) do
		atk_sum=atk_sum+math.max(tc:GetBaseAttack(),0)
	end
	return atk_sum
end

------------------------------------
--② 배틀 페이즈 중 발동 가능 (Quick Effect)
------------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local ct=Duel.GetCounter(tp,1,0,0x1)
	if ct==0 then return end
	Duel.RemoveCounter(tp,1,0,0x1,ct,REASON_COST)
	local atk=ct*600
	Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,0))
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

------------------------------------
--③ 덱 서치 : 스펠크래프트 마녀의 가마솥
------------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToDeckAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.thfilter(c)
	return c:IsCode(128770286) and c:IsAbleToHand() -- "스펠크래프트 마녀의 가마솥"
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

