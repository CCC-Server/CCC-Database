--드래곤 듀얼 임페리온 (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--융합 소재: 드래곤족 듀얼 몬스터 ×2
	Fusion.AddProcMixRep(c,true,true,s.matfilter,2,2)

	--① 대상 내성
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	--② 직접 공격 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e2)

	--③ 공격력 1000 상승 (1턴 1회)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.atkcon)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

--융합 소재: 드래곤족 듀얼 몬스터
function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_GEMINI,fc,sumtype,tp)
end

--③ 조건: 자신 필드에 한 번 더 소환된 드래곤족 몬스터 존재
function s.dualfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsSummonType(SUMMON_TYPE_DUAL)
end
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.dualfilter,tp,LOCATION_MZONE,0,1,nil)
end

--③ 처리: ATK +1000
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end
