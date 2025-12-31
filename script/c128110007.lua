--유네티스 네레실라
local s,id=GetID()
function s.initial_effect(c)
	--[Global Check: 바운스 횟수 카운팅]
	if not s.global_check_id then
		s.global_check_id=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TO_HAND)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end

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
	
	--[펜듈럼 효과 ②]: 메인 페이즈 기동 (패/묘지 특소 + P소환 제약) - 명칭 제약
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.pstg)
	e2:SetOperation(s.psop)
	c:RegisterEffect(e2)
	
	--[몬스터 효과 ①]: 융합 소환 (상대 필드 포함)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
	
	--[몬스터 효과 ②]: 바운스 횟수만큼 묘지로 보냄 + 일소
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e5:SetCountLimit(1,{id,3})
	e5:SetCondition(s.gycon)
	e5:SetTarget(s.gytg)
	e5:SetOperation(s.gyop)
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

-- Global check
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)
	if ct>0 then
		Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1,ct)
	end
end

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

-- [몬스터 효과 ①: 융합 소환]
function s.fusfilter1(c,e)
	return c:IsOnField() and not c:IsImmuneToEffect(e)
end
function s.fusfilter2(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0xc80) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		-- 필드 위의 융합 소재 가능한 몬스터 수집 (자신: 전부 / 상대: 앞면만)
		local mg1=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE,0,nil)
		local mg2=Duel.GetMatchingGroup(function(c) return c:IsCanBeFusionMaterial() and c:IsFaceup() end,tp,0,LOCATION_MZONE,nil)
		mg1:Merge(mg2)
		
		local res=Duel.IsExistingMatchingCard(s.fusfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg3=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(s.fusfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg3,mf,chkf)
			end
		end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetMatchingGroup(function(c) return c:IsCanBeFusionMaterial() and not c:IsImmuneToEffect(e) end,tp,LOCATION_MZONE,0,nil)
	local mg2=Duel.GetMatchingGroup(function(c) return c:IsCanBeFusionMaterial() and c:IsFaceup() and not c:IsImmuneToEffect(e) end,tp,0,LOCATION_MZONE,nil)
	mg1:Merge(mg2)
	
	local sg1=Duel.GetMatchingGroup(s.fusfilter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	local mg3=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg3=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(s.fusfilter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg3,mf,chkf)
	end
	if #sg1>0 or (sg2~=nil and #sg2>0) then
		local sg=sg1:Clone()
		if sg2 then sg:Merge(sg2) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		if sg1:IsContains(tc) and (sg2==nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp,ce:GetDescription())) then
			local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
			tc:SetMaterial(mat1)
			Duel.SendtoGrave(mat1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		else
			local mat2=Duel.SelectFusionMaterial(tp,tc,mg3,nil,chkf)
			local fop=ce:GetOperation()
			fop(ce,e,tp,tc,mat2)
		end
		tc:CompleteProcedure()
	end
end

-- [몬스터 효과 ②: 바운스 수만큼 묘지로 보내고 일소]
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Global check로 등록된 플래그 값을 가져옴 (0번 플레이어에 등록됨)
	local ct=Duel.GetFlagEffect(0,id)
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetFlagEffect(0,id)
	if ct==0 then return end
	
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	if #g==0 then return end
	
	-- 1 ~ ct(바운스 횟수) 중 선택 (최대 상대 필드 카드 수)
	local max_count = math.min(ct, #g)
	local nums={}
	for i=1,max_count do table.insert(nums,i) end
	local count=Duel.AnnounceNumber(tp,table.unpack(nums))
	
	for i=1,count do
		local sg=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
		if #sg==0 then break end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local tc=sg:Select(tp,1,1,nil):GetFirst()
		if tc then
			Duel.SendtoGrave(tc,REASON_EFFECT)
			if tc:IsLocation(LOCATION_GRAVE) then
				-- 묘지로 간 카드의 효과 발동 불가
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_TRIGGER)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
			end
		end
	end
	
	-- 스피릿 일소
	Duel.ShuffleHand(tp)
	if Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) 
		and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #sg>0 then
			local tc=sg:GetFirst()
			-- 릴리스 없이 소환
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