--스파클 아르카디아 듀얼 드래곤 (예시명)
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_TUNER),1,1,
		aux.FilterBoolFunctionEx(function(c) return c:IsSetCard(0x760) and c:IsType(TYPE_SYNCHRO) end),1,99)
	c:EnableReviveLimit()

	--① 물속성으로도 취급
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_ADD_ATTRIBUTE)
	e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e1:SetValue(ATTRIBUTE_WATER)
	c:RegisterEffect(e1)

	--② 1턴에 2회 공격 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(1)
	e2:SetCountLimit(1,{id,0})
	c:RegisterEffect(e2)

	--③ 발동 무효 및 제외
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

--------------------------------------------------
--③ 조건: 다른 스파클 아르카디아 싱크로 몬스터 존재
--------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x760) and c:IsType(TYPE_SYNCHRO)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp==1-tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,c)
end
--------------------------------------------------
--③ 타깃 / 처리
--------------------------------------------------
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
end
