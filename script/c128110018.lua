--SU(서브유니즌) (이름 미정)
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소재 불가
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	e0:SetValue(1)
	c:RegisterEffect(e0)
	--①: 덱 세트 및 바운스
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	local e1a=e1:Clone()
	e1a:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1a)
	--②: 위치 이동 및 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.mvcst)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
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

--① 효과 처리
function s.setfilter(c)
	return c:IsSetCard(0xc81) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_SZONE)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SSet(tp,g)>0 then
		local sg=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_SZONE,0,nil)
		if #sg>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
			local rg=sg:Select(tp,1,1,nil)
			Duel.SendtoHand(rg,nil,REASON_EFFECT)
		end
	end
end

--② 효과 처리
function s.mvcst(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0 end
	local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0)
	local nseq=math.log(zone,2)
	Duel.MoveSequence(c,nseq)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- "SU" 융합 몬스터(0xc81)만 소환 가능, 소재는 패/필드
		local params={
			fus_filter=function(c) return c:IsSetCard(0xc81) end,
			mat_filter=function(c) return c:IsLocation(LOCATION_HAND+LOCATION_ONFIELD) end
		}
		return Fusion.SummonEffTG(params)(e,tp,eg,ep,ev,re,r,rp,chk)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local params={
		fus_filter=function(c) return c:IsSetCard(0xc81) end,
		mat_filter=function(c) return c:IsLocation(LOCATION_HAND+LOCATION_ONFIELD) end
	}
	Fusion.SummonEffOP(params)(e,tp,eg,ep,ev,re,r,rp)
end

--③ 효과 처리
function s.efilter(e,te)
	local c=e:GetHandler()
	local tc=te:GetHandler()
	return (te:GetActivateLocation()&LOCATION_ONFIELD)~=0 
		and te:GetOwnerPlayer()~=e:GetHandlerPlayer() 
		and not c:GetColumnGroup():IsContains(tc)
end