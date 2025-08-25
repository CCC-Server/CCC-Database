--고스트릭 햄본
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x8d),4,2,s.ovfilter,aux.Stringid(id,0),Xyz.InfiniteMats)
	c:EnableReviveLimit()
	--①: 이 카드는 상대 몬스터 전부에 1회씩 공격할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--②: 관통
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e2)
	--③: 공격력/수비력 상승
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(aux.bdocon) -- 전투로 몬스터 파괴했을 때
	e3:SetCost(s.cost)
	e3:SetOperation(s.operation)
	e3:SetCountLimit(1,id)
	c:RegisterEffect(e3)
end
--엑시즈 소환 조건 (고스트릭 몬스터 또는 뒷면 표시 몬스터 위에)
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsSetCard(0x8d,xyzc) or c:IsFacedown()
end
--③ 비용: 소재 1개 제거
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
--③ 효과 처리
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:IsSetCard(0x8d) and c:IsLevelBelow(4) end,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)
	end
end



