--유네티스 세르펜티아
local s,id=GetID()
function s.initial_effect(c)
	--[스피릿 & 펜듈럼 공통 설정]
	Pendulum.AddProcedure(c) -- 수정됨: 펜듈럼 셋팅 함수 변경
	-- aux.AddSpiritProcedure(c,0) -- 삭제됨: 커스텀 바운스 로직 사용
	
	--[펜듈럼 효과 ①]: 패로 되돌리고 스피릿 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_PZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--[펜듈럼 효과 ②]: 대리 펜듈럼 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.pstg)
	e2:SetOperation(s.psop)
	c:RegisterEffect(e2)
	
	--[몬스터 효과 ①]: 소환 시 상대 카드 2장 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
	
	--[몬스터 효과 ②]: 메인 페이즈 덱 P세팅 + 일소
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e5:SetCountLimit(1,id+300)
	e5:SetCondition(s.pzcon)
	e5:SetTarget(s.pztg)
	e5:SetOperation(s.pzop)
	c:RegisterEffect(e5)
	
	--[몬스터 효과 ③]: 엔드 페이즈 바운스
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e6:SetCountLimit(1)
	e6:SetCondition(s.retcon)
	e6:SetOperation(s.retop)
	c:RegisterEffect(e6)
end
s.listed_series={0xc55}

-- [펜듈럼 효과 ①]
function s.cfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(0xc55) and c:IsSummonType(SUMMON_TYPE_NORMAL)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.nsfilter(c)
	return c:IsType(TYPE_SPIRIT) and c:IsSummonable(true,nil)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local g=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #g>0 then
			Duel.Summon(tp,g:GetFirst(),true,nil)
		end
	end
end

-- [펜듈럼 효과 ②]
function s.psfilter(c,e,tp,lscale,rscale)
	local lv=c:GetLevel()
	return c:IsSetCard(0xc55) and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE))
		and lv>lscale and lv<rscale and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_PENDULUM,tp,false,false)
end
function s.pstg(e,tp,eg,ep,ev,re,r,rp,chk)
	local pc1=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local pc2=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	if not pc1 or not pc2 then return false end
	local lscale=math.min(pc1:GetScale(),pc2:GetScale())
	local rscale=math.max(pc1:GetScale(),pc2:GetScale())
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.psfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,lscale,rscale) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.psop(e,tp,eg,ep,ev,re,r,rp)
	local pc1=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local pc2=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	if not pc1 or not pc2 then return end
	local lscale=math.min(pc1:GetScale(),pc2:GetScale())
	local rscale=math.max(pc1:GetScale(),pc2:GetScale())
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.psfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,lscale,rscale)
	if #g>0 then
		Duel.SpecialSummon(g,SUMMON_TYPE_PENDULUM,tp,tp,false,false,POS_FACEUP)
	end
end

-- [몬스터 효과 ①: 상대 필드의 카드 2장 파괴]
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,2,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,2,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,2,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- [몬스터 효과 ②: 덱 P세팅 및 스피릿 일소]
function s.pzcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.pcfilter(c)
	return c:IsSetCard(0xc55) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function s.nsfilter2(c)
	return c:IsType(TYPE_SPIRIT)
end
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) 
		and Duel.IsExistingMatchingCard(s.pcfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.nsfilter2,tp,LOCATION_HAND,0,1,nil) 
	end
end
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckPendulumZones(tp) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.pcfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
			-- 일반 소환 처리
			Duel.ShuffleHand(tp)
			local sg=Duel.GetMatchingGroup(s.nsfilter2,tp,LOCATION_HAND,0,nil)
			if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
				local tc=sg:Select(tp,1,1,nil):GetFirst()
				if tc then
					-- 릴리스 없이 일반 소환 효과 부여
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_SUMMON_PROC)
					e1:SetCondition(s.ntcon)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e1)
					Duel.Summon(tp,tc,true,nil)
				end
			end
		end
	end
end
function s.ntcon(e,c,minc)
	if c==nil then return true end
	return minc==0 and c:GetLevel()>4 and Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
end

-- [몬스터 효과 ③: 엔드 페이즈 바운스]
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (c:IsSummonType(SUMMON_TYPE_NORMAL) or c:IsSummonType(SUMMON_TYPE_PENDULUM))
		and c:IsFaceup() and c:GetTurnID()==Duel.GetTurnCount()
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.SendtoHand(c,nil,REASON_EFFECT)
end