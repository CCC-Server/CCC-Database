--SU(서브유니즌) 듀얼세일 터보
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 절차
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc81),2)
	--특수 소환 (릴리스)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetTarget(s.sprtg)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)
	--①: 공격력 배가
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
	--②: 이동/교체 및 효과 무효화
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.mvtg)
	e2:SetOperation(s.mvop)
	c:RegisterEffect(e2)
	--③: 같은 세로열 이외의 필드 발동 효과 내성
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)
end

--특수 소환 처리
function s.sprfilter(c)
	return c:IsSetCard(0xc81) and c:IsReleasable()
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
	if #sg==2 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	Duel.Release(sg,REASON_COST+REASON_MATERIAL)
end

--① 효과 처리
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e1:SetCondition(s.atkcon)
	e1:SetOperation(s.atkop_val)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not d then return false end
	if a:IsControler(1-tp) then a,d=d,a end
	return a:IsSetCard(0xc81) and a:IsControler(tp)
end
function s.atkop_val(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if a:IsControler(1-tp) then a=d end
	
	local e1=Effect.CreateEffect(e:GetOwner())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetValue(a:GetAttack()*2)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE_CAL)
	a:RegisterEffect(e1)
end

--② 효과 처리
function s.swapfilter(c)
	return c:IsSetCard(0xc81) and c:IsFaceup() and c:GetSequence()<5
end
function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0
	local b2=Duel.IsExistingMatchingCard(s.swapfilter,tp,LOCATION_MZONE,0,1,c)
	if chk==0 then return b1 or b2 end
end
function s.mvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) or not c:IsLocation(LOCATION_MZONE) then return end
	
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0
	local b2=Duel.IsExistingMatchingCard(s.swapfilter,tp,LOCATION_MZONE,0,1,c)
	
	local op=0
	if b1 and b2 then
		--0: 이동, 1: 맞바꾼다
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end
	
	if op==0 then
		-- [수정] HINTMSG_TOZONE -> HINTMSG_SELECT로 변경 (Parameter 3 nil 오류 해결)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
		-- 변수명 충돌 방지
		local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0)
		-- 정수 변환 보장
		local nseq=math.floor(math.log(zone,2))
		Duel.MoveSequence(c,nseq)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
		local g=Duel.SelectMatchingCard(tp,s.swapfilter,tp,LOCATION_MZONE,0,1,1,c)
		local tc=g:GetFirst()
		if tc then
			-- 안전한 교체 로직 적용
			if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_MZONE) and tc:IsLocation(LOCATION_MZONE) then
				Duel.SwapSequence(c,tc)
			end
		end
	end
	
	--전투 상대 효과 무효화 적용
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_BATTLE_START)
	e1:SetOperation(s.disop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not a or not d then return end
	local bc=nil
	if a:IsControler(tp) and a:IsSetCard(0xc81) then bc=d end
	if d:IsControler(tp) and d:IsSetCard(0xc81) then bc=a end
	
	if bc and bc:IsControler(1-tp) and bc:IsRelateToBattle() and not bc:IsDisabled() then
		local e1=Effect.CreateEffect(e:GetOwner())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		bc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetOwner())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		bc:RegisterEffect(e2)
	end
end

--③ 효과 처리
function s.efilter(e,te)
	local c=e:GetHandler()
	local tc=te:GetHandler()
	local loc=te:GetActivateLocation()
	return (loc&LOCATION_ONFIELD)~=0 and te:GetOwnerPlayer()~=e:GetHandlerPlayer() and not c:GetColumnGroup():IsContains(tc)
end