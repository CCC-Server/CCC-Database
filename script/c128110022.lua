--SU(서브유니즌) 제트 핀테일
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 절차
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc81),3)
	
	--특수 소환 (레벨 합계 9)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetTarget(s.sprtg)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)
	
	--①: 직접 공격 부여
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.eff1op)
	c:RegisterEffect(e1)
	
	--②: 이동/교체 및 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.mvtg)
	e2:SetOperation(s.mvop)
	c:RegisterEffect(e2)
	
	--③: 내성
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
	return c:IsSetCard(0xc81) and c:IsReleasable() and c:HasLevel()
end
function s.rescon(sg,e,tp,mg)
	return sg:GetSum(Card.GetLevel)==9 and Duel.GetLocationCountFromEx(tp,tp,sg,e:GetHandler())>0
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	return aux.SelectUnselectGroup(g,e,tp,1,9,s.rescon,0)
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,9,s.rescon,1,tp,HINTMSG_RELEASE,nil,nil,true)
	if sg then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if sg then
		Duel.Release(sg,REASON_COST+REASON_MATERIAL)
	end
end

--① 효과 처리
function s.eff1op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c:IsSetCard(0xc81) end)
	e1:SetCondition(s.dircon)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.dircon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
		and not Duel.IsExistingMatchingCard(Card.IsAttackPos,tp,0,LOCATION_MZONE,1,nil)
end

--② 효과 처리
function s.swapfilter(c)
	return c:IsSetCard(0xc81) and c:IsFaceup() and c:GetSequence()<5
end
function s.matfilter(c)
	return c:IsAbleToRemove() and c:IsCanBeFusionMaterial()
end
function s.fusfilter(c,e,tp,m,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0xc81)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end

function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0
	local b2=Duel.IsExistingMatchingCard(s.swapfilter,tp,LOCATION_MZONE,0,1,c)
	if chk==0 then
		local chkf=tp
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
		local res=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,chkf)
		return (b1 or b2) and res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.mvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsControler(1-tp) or not c:IsLocation(LOCATION_MZONE) or not c:IsRelateToEffect(e) then return end
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0
	local b2=Duel.IsExistingMatchingCard(s.swapfilter,tp,LOCATION_MZONE,0,1,c)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end
	
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
		-- [수정] local s -> local zone (테이블 s 덮어쓰기 방지)
		local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0)
		-- [수정] math.floor 추가 (정수형 변환)
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
	
	Duel.BreakEffect()
	local chkf=tp
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
	-- [수정] 위에서 s 변수 충돌을 해결했으므로 s.fusfilter가 정상 작동함
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,chkf)
	local tc=sg:GetFirst()
	if tc then
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
		tc:SetMaterial(mat)
		Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end

--③ 효과 처리
function s.efilter(e,te)
	local c=e:GetHandler()
	local tc=te:GetHandler()
	local loc=te:GetActivateLocation()
	return (loc&LOCATION_ONFIELD)~=0 and te:GetOwnerPlayer()~=e:GetHandlerPlayer() and not c:GetColumnGroup():IsContains(tc)
end