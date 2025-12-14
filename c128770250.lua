--Dual Dragon Summoner (듀얼 드래곤 서머너)
local s,id=GetID()
function s.initial_effect(c)
	--① 듀얼 몬스터 취급
	Gemini.AddProcedure(c)

	--② 드래곤족 듀얼 몬스터 1장을 릴리스하고 어드밴스 소환 가능
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SUMMON_PROC)
	e1:SetCondition(s.sumcon)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)

	--③-1 듀얼 상태 효과: 상대 몬스터 전부에 1회씩 공격 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_ATTACK_ALL)
	e2:SetCondition(Gemini.EffectStatusCondition)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--③-2 듀얼 상태 효과: 상대의 배틀 페이즈 중 효과 발동 무효 및 제외
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

--------------------------------------------
--② 드래곤족 듀얼 몬스터 릴리스 어드밴스 소환
--------------------------------------------
function s.relfilter(c)
	return c:IsReleasable() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end
function s.sumcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	return minc<=1 and Duel.CheckReleaseGroup(tp,s.relfilter,1,false,1,true,c,tp,nil,false,nil)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectReleaseGroup(tp,s.relfilter,1,1,false,true,true,c,tp,nil,false,nil)
	Duel.Release(g,REASON_COST)
end

--------------------------------------------
--③-2 듀얼 상태 효과: 배틀 페이즈 중 발동 무효 + 제외
--------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE
		and rp==1-tp and Duel.IsChainNegatable(ev)
		and Gemini.EffectStatusCondition(e) -- 듀얼 상태일 때만
end
function s.costfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsAbleToRemoveAsCost()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
end
