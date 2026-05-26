--드래고니아-격노한 진룡 이트레녹
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon
Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0xc05), 1, 1, Synchro.NonTuner(Card.IsSetCard, 0xc05), 1, 99)
	c:EnableReviveLimit()
	-- ①: 전투/효과로 파괴되지 않음
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e2)
	-- ②: LP 1000 지불 → 공격력 2배 (상대 턴 종료시까지)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

-- ② LP 1000 지불
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
-- ② 공격력 2배 처리
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local atk=c:GetAttack()
		if atk>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(atk*2)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2) 
			-- (2)로 설정해 상대 턴 종료시까지 유지
			c:RegisterEffect(e1)
		end
	end
end
