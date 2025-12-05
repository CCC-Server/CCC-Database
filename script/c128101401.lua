--Mist Valley Turbulence
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	-----------------------------------------
	-- (1) Synchro Summon "Mist Valley" Synchro
	-----------------------------------------
	--①-1: "Mist Valley" monster is Special Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.sccon1)
	e1:SetTarget(s.sctg)
	e1:SetOperation(s.scop)
	c:RegisterEffect(e1)
	--①-2: Opponent activates a card or effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.sccon2)
	e2:SetTarget(s.sctg)
	e2:SetOperation(s.scop)
	c:RegisterEffect(e2)
	-----------------------------------------
	-- (2) Set itself from GY (OPT)
	-----------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id) -- (2) 효과만 1턴에 1번
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

-- 안개골짜기 = 0x37

-----------------------------------------
-- (1) 조건들
-----------------------------------------
-- "Mist Valley" 몬스터가 특소되었을 때
function s.scfilter1(c)
	return c:IsFaceup() and c:IsSetCard(0x37)
end
function s.sccon1(e,tp,eg,ep,ev,re,r,rp)
	-- 어느 쪽 필드든 상관 없이 "Mist Valley" 특소 시 발동
	return eg:IsExists(s.scfilter1,1,nil)
end

-- 상대가 카드 / 효과를 발동했을 때
function s.sccon2(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp -- 상대가 발동
end

-- 싱크로 소환 가능 여부 체크
function s.synfilter(c)
	return c:IsSetCard(0x37) and c:IsType(TYPE_SYNCHRO) and c:IsSynchroSummonable(nil)
end
function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local sc=g:GetFirst()
	if sc then
		-- 자신 필드의 몬스터만 소재로 사용해서 싱크로 소환
		Duel.SynchroSummon(tp,sc,nil)
	end
end

-----------------------------------------
-- (2) GY에서 세트
-----------------------------------------
function s.mvsynfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x37)
		and c:IsType(TYPE_SYNCHRO)
		and c:IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	-- 어느 플레이어든 "Mist Valley" 싱크로가 싱크로 소환되면 OK
	return eg:IsExists(s.mvsynfilter,1,nil)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and c:IsSSetable()
	end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp,c)
	end
end
