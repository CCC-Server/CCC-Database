--하이랜드 링크 마스터
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,nil) -- "하이랜드" 몬스터 2장 이상

	-----------------------------------------------------
	--① 효과 : 묘지의 "하이랜드" 몬스터의 효과 복사
	-----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,{id,1}) -- 이름별 1턴 1번
	e1:SetCost(s.copycost)
	e1:SetTarget(s.copytg)
	e1:SetOperation(s.copyop)
	c:RegisterEffect(e1)

	-----------------------------------------------------
	--② 효과 : 상대 몬스터 효과 발동 무효 및 파괴
	-----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2}) -- 이름별 1턴 1번
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------
-- 링크 소재: "하이랜드" 몬스터
-----------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x755,lc,sumtype,tp)
end

-----------------------------------------------------
-- ① 효과: 묘지의 하이랜드 몬스터 1장을 제외하고 그 효과 복사
-----------------------------------------------------
function s.copyfilter(c)
	return c:IsSetCard(0x755) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	Duel.Remove(tc,POS_FACEUP,REASON_COST)
	e:SetLabelObject(tc)
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()
	if not tc or not tc:IsType(TYPE_MONSTER) then return end
	local code=tc:GetOriginalCodeRule()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END,1)
	end
end

-----------------------------------------------------
-- ② 효과: 상대 몬스터 효과 발동 무효 & 파괴
-----------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x755)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end
