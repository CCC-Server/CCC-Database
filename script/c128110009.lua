--유네티스 요르무겐
local s,id=GetID()
function s.initial_effect(c)
	--[융합 소재 설정]
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunction(Card.IsSetCard,0xc80),aux.FilterBoolFunction(Card.IsSetCard,0xc80),aux.FilterBoolFunction(Card.IsLevelAbove,5))
	
	--[특수 소환 절차]: 패/필드 릴리스 후 엑스트라 덱 특소 (융합 소환 아님)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	--[효과 ①]: 융합 소환 시 펜듈럼 세팅
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
	e1:SetTarget(s.pctg)
	e1:SetOperation(s.pcop)
	c:RegisterEffect(e1)

	--[효과 ②]: "유네티스" 일반 소환 시 존 봉쇄
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100) -- 명칭 제약
	e2:SetCondition(s.lkcon)
	e2:SetTarget(s.lktg)
	e2:SetOperation(s.lkop)
	c:RegisterEffect(e2)

	--[효과 ③]: 묘지 특소 (프리 체인) + 엑덱 되돌아감
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end
s.listed_series={0xc80}

-- [특수 소환 절차: 유네티스 x2 + 레벨 5 이상 x1 릴리스]
function s.spfilter(c)
	return (c:IsSetCard(0xc80) or c:IsLevelAbove(5)) and c:IsReleasable() and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
end
function s.rescon(sg,e,tp,mg)
	-- 유네티스 2장 이상 포함하고, 레벨 5 이상이 1장 이상 존재해야 함 (총 3장)
	-- (유네티스이면서 레벨 5 이상인 카드는 양쪽 조건 충족 가능)
	return sg:GetCount()==3 
		and sg:FilterCount(Card.IsSetCard,nil,0xc80)>=2 
		and sg:IsExists(Card.IsLevelAbove,1,nil,5)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	return aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,0)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,1,tp,HINTMSG_RELEASE)
	if #sg>0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	Duel.Release(sg,REASON_COST)
end

-- [효과 ①: P존 세팅]
function s.pcfilter(c)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function s.pctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp)
		and Duel.IsExistingMatchingCard(s.pcfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,2,nil) end
end
function s.pcop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckPendulumZones(tp) then return end
	local g=Duel.GetMatchingGroup(s.pcfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,nil)
	if #g<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local sg=g:Select(tp,2,2,nil)
	if #sg>0 then
		for tc in aux.Next(sg) do
			Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
		end
	end
end

-- [효과 ②: 존 봉쇄]
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	return tc:IsSetCard(0xc80) and tc:IsControler(tp)
end
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE+LOCATION_SZONE)>0 end
end
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	-- 상대 필드의 메인 몬스터 존 또는 마법&함정 존 1곳 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ZONE)
	local zone=Duel.SelectDisableField(tp,1,0,LOCATION_MZONE+LOCATION_SZONE,0)
	if zone>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_DISABLE_FIELD)
		e1:SetOperation(function(e) return zone end)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- [효과 ③: 묘지 소생]
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 필드를 벗어날 경우 엑스트라 덱으로
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_DECK) -- 융합 몬스터는 덱으로 가면 엑스트라 덱으로 감
		c:RegisterEffect(e1,true)
	end
end