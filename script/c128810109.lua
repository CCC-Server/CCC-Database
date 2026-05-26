--드래고니아-악동 스완
local s, id = GetID()
function s.initial_effect(c)
	-- 싱크로 소환 조건: 튜너 1장 + 튜너 이외 몬스터 1장 이상
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
    c:EnableReviveLimit()
	-- ① 묘지의 카드 수 × 100만큼 공격력 상승
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- ② 데미지 스텝 개시시에 공격력 300 상승 (1턴에 1번)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_START)
	e2:SetCondition(s.condition)
	e2:SetOperation(s.operation)
	e2:SetCountLimit(1, id)
	c:RegisterEffect(e2)
end

s.listed_series={0xc05}

-- ① 효과: 묘지의 카드 수 × 100
function s.atkval(e, c)
	return Duel.GetFieldGroupCount(0, LOCATION_GRAVE, LOCATION_GRAVE) * 100
end

-- ② 효과 발동 조건: 이 카드가 전투에 참여할 때
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsRelateToBattle()
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(300)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end