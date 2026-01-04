local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 조건
	c:EnableReviveLimit()
	--라이브러리 호환성을 고려한 융합 소재 설정 (어둠 속성 드래곤족 x 2)
	if not Fusion then Fusion={} end
	if Fusion.AddProcMixN then
		Fusion.AddProcMixN(c,true,true,s.ffilter,2)
	else
		aux.AddFusionProcMix(c,true,true,s.ffilter,s.ffilter)
	end
	
	--특수 소환 절차 (필드의 반달기온 관련 몬스터 2장 릴리스)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)
	
	--①: 자신 묘지의 카운터 함정을 2장까지 세트 (같은 이름은 1장까지)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	
	--②: 마법 / 함정 효과 발동 무효 및 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

s.listed_names={24857466}

-- 융합 소재 필터
function s.ffilter(c,fc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp) and c:IsRace(RACE_DRAGON,fc,sumtype,tp)
end

-- 특수 소환 절차용 필터
function s.sprfilter(c)
	return (c:IsCode(24857466) or c:ListsCode(24857466)) and c:IsReleasable()
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.sprfilter,tp,LOCATION_MZONE,0,2,nil)
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local sg=g:Select(tp,2,2,nil)
	if sg then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST)
	g:DeleteGroup()
end

-- ①번 효과 타겟팅 (안전한 수동 선택 로직)
function s.setfilter(c)
	return c:IsType(TYPE_COUNTER) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end -- 개별 타겟 체크는 하지 않음
	if chk==0 then return Duel.IsExistingTarget(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
	
	local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_GRAVE,0,nil)
	local sg=Group.CreateGroup()
	
	-- 첫 번째 카드 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g1=g:Select(tp,1,1,nil)
	sg:Merge(g1)
	
	-- 이름이 다른 두 번째 카드가 있으면 추가 선택 가능
	local g_rest=g:Filter(function(c) return not c:IsCode(g1:GetFirst():GetCode()) end, nil)
	if #g_rest>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g2=g_rest:Select(tp,1,1,nil)
		sg:Merge(g2)
	end
	
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,sg,#sg,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end

-- ②번 효과
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and (re:IsActiveType(TYPE_SPELL) or re:IsActiveType(TYPE_TRAP))
		and Duel.IsChainNegatable(ev)
end
function s.remfilter(c)
	return c:IsType(TYPE_COUNTER) and c:IsAbleToRemove()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		if Duel.Destroy(eg,REASON_EFFECT)>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local g=Duel.SelectMatchingCard(tp,s.remfilter,tp,LOCATION_GRAVE,0,1,1,nil)
			if #g>0 then
				Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end