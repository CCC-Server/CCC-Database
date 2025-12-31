--SU(서브유니즌) 서지 어헤드
local s,id=GetID()
function s.initial_effect(c)
	--①: 세로열 마법/함정 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	--②: 공격력 상승 및 관통 (묘지 제외)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.atkcon)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

--① 효과 처리
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc81) and c:IsType(TYPE_MONSTER)
end

function s.desfilter(c,g)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and g:IsContains(c)
end

function s.chainlm(e,rp,tp)
	-- 세트된 카드의 발동을 막음 (필드에서 발동하는 마법/함정으로 간주하여 처리)
	return not (e:IsActiveType(TYPE_SPELL+TYPE_TRAP) and e:GetHandler():IsOnField())
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 자신 필드의 "SU" 몬스터 확인
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		for tc in aux.Next(g) do
			local cg=tc:GetColumnGroup()
			if Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil,cg) then return true end
		end
		return false
	end
	
	-- "SU" 융합 몬스터가 이 카드(발동한 마법)와 같은 세로열에 있는지 확인
	-- 발동 시점의 Chain Limit 적용
	local c=e:GetHandler()
	local fusion_check=false
	if c:IsLocation(LOCATION_SZONE) then
		local cg=c:GetColumnGroup()
		if cg:IsExists(function(c) return c:IsFaceup() and c:IsSetCard(0xc81) and c:IsType(TYPE_FUSION) and c:IsControler(tp) end, 1, nil) then
			fusion_check=true
		end
	end
	
	if fusion_check then
		Duel.SetChainLimit(s.chainlm)
	end
	
	local dg=Group.CreateGroup()
	for tc in aux.Next(g) do
		local cg=tc:GetColumnGroup()
		local destroy_targets=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil,cg)
		dg:Merge(destroy_targets)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,dg,#dg,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	local dg=Group.CreateGroup()
	for tc in aux.Next(g) do
		local cg=tc:GetColumnGroup()
		local destroy_targets=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil,cg)
		dg:Merge(destroy_targets)
	end
	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

--② 효과 처리
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	if not a then return false end
	if a:IsControler(1-tp) then a=Duel.GetAttackTarget() end
	return a and a:IsControler(tp) and a:IsSetCard(0xc81) 
		and Duel.IsBattlePhase() 
		and (Duel.GetCurrentPhase()~=PHASE_DAMAGE or not Duel.IsDamageCalculated())
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not a then return end
	if a:IsControler(1-tp) then a,d=d,a end
	
	if a and a:IsRelateToBattle() and a:IsFaceup() then
		local val=0
		if d and d:IsRelateToBattle() and d:IsFaceup() then
			val=d:GetAttack()
		end
		
		-- 공격력 상승
		if val>0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(val)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			a:RegisterEffect(e1)
		end
		
		-- 관통 효과
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_PIERCE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		a:RegisterEffect(e2)
	end
end