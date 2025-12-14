--Dragon Dual Cataclysm Fusion
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 조건: 드래곤족 듀얼 몬스터 ×3
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.ffilter,3,3)
	--듀얼 몬스터 취급 (필드에서는 일반 몬스터로, 1번 더 소환 가능)
	Gemini.AddProcedure(c)

	--②-1 필드 전멸 + 데미지
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(TIMING_MAIN_END,TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(Gemini.EffectStatusCondition)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	--②-2 패/묘지/제외 몬스터 효과 무효 + 1500 데미지
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	e2:SetCondition(Gemini.EffectStatusCondition)
	c:RegisterEffect(e2)
end

--융합 소재: 드래곤족 듀얼 몬스터
function s.ffilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_GEMINI,fc,sumtype,tp)
end

--②-1 필드 전멸 + 데미지
function s.desfilter(c)
	return c:IsFaceup() or c:IsLocation(LOCATION_MZONE)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*400)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g>0 then
		local ct=Duel.Destroy(g,REASON_EFFECT)
		if ct>0 then
			Duel.Damage(1-tp,ct*400,REASON_EFFECT)
		end
	end
end

--②-2 패/묘지/제외 몬스터 효과 무효 + 1500 데미지
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not re:IsActiveType(TYPE_MONSTER) then return false end
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return (loc==LOCATION_HAND or loc==LOCATION_GRAVE or loc==LOCATION_REMOVED)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsChainNegatable(ev) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1500)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Damage(1-tp,1500,REASON_EFFECT)
	end
end
