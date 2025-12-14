--Sparkle Arcadia Synchro - Fixed Version
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 절차
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,Synchro.NonTunerEx(Card.IsSetCard,0x760),1,99)
	c:EnableReviveLimit()
	
	--------------------------------------------------
	--① 싱크로 소환 성공시 : 라이프 지불 → 파괴 + ATK 상승
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	
	--------------------------------------------------
	--② 자신의 라이프 < 상대 라이프 → 배틀페이즈 중 효과 내성
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.immcon)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)
end

--------------------------------------------------
--① 조건: 싱크로 소환 성공시
--------------------------------------------------
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

--------------------------------------------------
--① 대상 설정 (라이프 지불량 선택)
--------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,100) end
end

--------------------------------------------------
--① 처리 : 라이프 지불 후 파괴 + ATK 상승
--------------------------------------------------
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local lp=Duel.GetLP(tp)
	if lp<=0 then return end
	local maxpay=math.min(4000,lp)
	
	-- 라이프 지불량 선택
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
	local pay=Duel.AnnounceNumber(tp,1000,2000,3000,4000)
	if pay>maxpay then pay=maxpay end
	
	-- 라이프 지불
	if not Duel.CheckLPCost(tp,pay) then return end
	Duel.PayLPCost(tp,pay)
	Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,2))
	
	-- 파괴 대상군 재획득
	local g=Duel.GetMatchingGroup(function(tc) 
		return tc:IsOnField() and tc:IsControler(1-tp) and tc:IsAttackBelow(pay) 
	end,tp,0,LOCATION_MZONE,nil)
	
	-- 실제 파괴 처리
	if #g>0 then
		local ct=Duel.Destroy(g,REASON_EFFECT)
		if ct>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(ct*300)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	else
		Duel.Hint(HINT_MESSAGE,tp,HINTMSG_NEGATE)
	end
end

--------------------------------------------------
--② 조건: 자신 라이프 < 상대 라이프
--------------------------------------------------
function s.immcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetLP(tp)<Duel.GetLP(1-tp)
		and Duel.GetCurrentPhase()>=PHASE_BATTLE_START 
		and Duel.GetCurrentPhase()<=PHASE_BATTLE
end

--------------------------------------------------
--② 내성 조건: 배틀페이즈 중 상대가 발동한 효과에만
--------------------------------------------------
function s.immval(e,te)
	local tp=e:GetHandlerPlayer()
	return te:GetOwnerPlayer()~=tp
		and Duel.GetCurrentPhase()>=PHASE_BATTLE_START 
		and Duel.GetCurrentPhase()<=PHASE_BATTLE
end
