--유네티스 코카트리스
local s,id=GetID()
function s.initial_effect(c)
	--[스피릿 & 펜듈럼 공통 설정]
	Pendulum.AddProcedure(c)
	
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
	
	--[펜듈럼 효과 ②]: 메인 페이즈 기동 (패/묘지 특소 + P소환 제약) - 명칭 제약 적용
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.pstg)
	e2:SetOperation(s.psop)
	c:RegisterEffect(e2)
	
	--[몬스터 효과 ①]: 패 발동 (P세팅 + 서치) - 기동 효과
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,{id,2})
	e3:SetCost(s.pzc_cost)
	e3:SetTarget(s.pzc_tg)
	e3:SetOperation(s.pzc_op)
	c:RegisterEffect(e3)
	--[몬스터 효과 ①]: 패 발동 (P세팅 + 서치) - 유발 효과 (상대 패 몬스터 효과 대응)
	local e4=e3:Clone()
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.pzc_con_chain)
	c:RegisterEffect(e4)
	
	--[몬스터 효과 ②]: 레벨 증가 + 회복 + 일소
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_RECOVER+CATEGORY_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,{id,3})
	e5:SetTarget(s.lvtg)
	e5:SetOperation(s.lvop)
	c:RegisterEffect(e5)
	
	--[몬스터 효과 ③]: 엔드 페이즈 바운스 (강제 유발)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,4))
	e6:SetCategory(CATEGORY_TOHAND)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e6:SetCountLimit(1)
	e6:SetCondition(s.retcon)
	e6:SetTarget(s.rettg)
	e6:SetOperation(s.retop)
	c:RegisterEffect(e6)
end
s.listed_series={0xc80}

-- [펜듈럼 효과 ①]
function s.cfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(0xc80) and c:IsSummonType(SUMMON_TYPE_NORMAL)
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
	return c:IsSetCard(0xc80) and c:IsType(TYPE_PENDULUM)
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE))
		and c:GetLevel()>lscale and c:GetLevel()<rscale
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.pstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local pc=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
		if pc==c then pc=Duel.GetFieldCard(tp,LOCATION_PZONE,1) end
		if not pc then return false end
		
		local lscale=c:GetScale()
		local rscale=pc:GetScale()
		if lscale>rscale then lscale,rscale=rscale,lscale end
		
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.psfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,lscale,rscale)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.psop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 펜듈럼 소환 불가 제약
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c,sump,sumtype,sumpos,targetp,se) 
		return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM 
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	local pc=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	if pc==c then pc=Duel.GetFieldCard(tp,LOCATION_PZONE,1) end
	if not pc then return end
	
	local lscale=c:GetScale()
	local rscale=pc:GetScale()
	if lscale>rscale then lscale,rscale=rscale,lscale end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.psfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,lscale,rscale)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- [몬스터 효과 ①: 패 효과 발동]
function s.pzc_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	Duel.ConfirmCards(1-tp,e:GetHandler())
end
function s.pzc_con_chain(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 패의 몬스터 효과를 발동했을 경우 (loc 안전성 체크 추가)
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return loc and rp==1-tp and re:IsActiveType(TYPE_MONSTER) and (loc&LOCATION_HAND)~=0
end
function s.srchfilter(c)
	return (c:IsType(TYPE_SPIRIT) or c:IsType(TYPE_PENDULUM)) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.pzc_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp)
		and Duel.IsExistingMatchingCard(s.srchfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.pzc_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	-- P존에 놓기
	if Duel.CheckPendulumZones(tp) and Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
		-- 서치
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.srchfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
		
		-- 엑스트라 덱 제약 (유네티스만 가능)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetDescription(aux.Stringid(id,5))
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0xc80)
end

-- [몬스터 효과 ②: 레벨 증가 + 회복 + 일소]
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1600)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		-- 레벨 8 올리기
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(8)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
		
		-- 라이프 회복
		if Duel.Recover(tp,1600,REASON_EFFECT)>0 then
			-- 스피릿 일소
			Duel.ShuffleHand(tp)
			if Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,6)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
				local g=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
				if #g>0 then
					Duel.Summon(tp,g:GetFirst(),true,nil)
				end
			end
		end
	end
end

-- [몬스터 효과 ③: 엔드 페이즈 바운스]
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (c:IsSummonType(SUMMON_TYPE_NORMAL) or c:IsSummonType(SUMMON_TYPE_PENDULUM))
		and c:IsFaceup() and c:GetTurnID()==Duel.GetTurnCount()
end
function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end