local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
end

-- 💥 파괴 타겟 설정
function s.desfilter(c)
	return c:IsSetCard(0x769) and c:IsFaceup()
end
function s.oppfilter(c)
	return c:IsDestructable()
end
function s.get_type_count(tp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	local races = {}
	for tc in aux.Next(g) do
		races[tc:GetRace()] = true
	end
	local count = 0
	for _ in pairs(races) do count = count + 1 end
	return count
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ct=s.get_type_count(tp)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and s.oppfilter(chkc) end
	if chk==0 then return ct>0 and Duel.IsExistingTarget(s.oppfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.oppfilter,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

-- 💥 파괴 실행
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
