--제 9사도-건설자 루크
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 레벨 12 몬스터 × 2
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsLevel,12),2)
	c:EnableReviveLimit()
	--룰상 "헤블론" 카드로 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0xc06)
	c:RegisterEffect(e0)

	--① 공격력 상승: 소재 수 × 500
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	--② 효과 부여 (소재 수에 따라)
	--●1개 이상: 전투/효과로 파괴되지 않음
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetCondition(s.indcon1)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e3)

	--●3개 이상: 속성을 어둠으로도 취급
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_ADD_ATTRIBUTE)
	e4:SetValue(ATTRIBUTE_DARK)
	e4:SetCondition(s.indcon3)
	c:RegisterEffect(e4)

	--●5개 이상: 이 카드를 대상으로 하는 효과 이외에는 받지 않음
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetCondition(s.indcon5)
	e5:SetValue(s.immval)
	c:RegisterEffect(e5)

	--●7개 이상: 대상/공격 선택 시 발동 → 상대 필드 전부 파괴 + LP 절반
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DESTROY)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_BECOME_TARGET)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,{id,1})
	e6:SetCondition(s.indcon7)
	e6:SetTarget(s.destg)
	e6:SetOperation(s.desop)
	c:RegisterEffect(e6)
	local e7=e6:Clone()
	e7:SetCode(EVENT_BE_BATTLE_TARGET)
	c:RegisterEffect(e7)
end

--① ATK 상승
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

--② 조건 체크
function s.indcon1(e)
	return e:GetHandler():GetOverlayCount()>=1
end
function s.indcon3(e)
	return e:GetHandler():GetOverlayCount()>=3
end
function s.indcon5(e)
	return e:GetHandler():GetOverlayCount()>=5
end
function s.indcon7(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()>=7
end

--② 5개 이상 면역 처리: 이 카드를 대상으로 하는 효과만 통과
function s.immval(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
		and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
		and not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
		or (re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) and not re:GetTarget():IsContains(e:GetHandler()))
end

--② 7개 이상: 파괴 + LP 절반
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
	local lp=Duel.GetLP(1-tp)
	Duel.SetLP(1-tp,math.floor(lp/2))
end