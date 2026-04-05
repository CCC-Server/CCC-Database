-- 스타토치 아카데미 모니에
local s,id=GetID()

function s.initial_effect(c)
	local SETCODE_STARTORCH = 0xc57

	-- ①: 패에서 발동하는 의식 소환 (사이버스족 전용)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.ritcon)
	e1:SetTarget(s.rittg(SETCODE_STARTORCH))
	e1:SetOperation(s.ritop(SETCODE_STARTORCH))
	c:RegisterEffect(e1)

	-- ②: 릴리스 또는 파괴 시 선택 발동 (각 효과별 1회 제한)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetTarget(s.choosetg(SETCODE_STARTORCH))
	e2:SetOperation(s.chooseop(SETCODE_STARTORCH))
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_DESTROYED)
	c:RegisterEffect(e3)
end

s.listed_series={0xc57}

-- ① 메인 페이즈 조건
function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

-- 사이버스족 의식 몬스터 체크 및 소재 확인
function s.ritfilter(c,e,tp,setcode)
	if not (c:IsRace(RACE_CYBERSE) and c:IsRitualMonster()) then return false end
	
	-- 릴리스 소재(패/필드) + 파괴 가능한 스타토치(필드)
	local mg=Duel.GetRitualMaterial(tp)
	local dg=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,setcode)
	mg:Merge(dg)
	
	return c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
		and mg:CheckWithSumGreater(Card.GetRitualLevel,c:GetLevel(),c)
end

function s.rittg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then 
			return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,setcode) 
		end
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	end
end

function s.ritop(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ritfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,setcode)
		local tc=tg:GetFirst()
		if tc then
			local mg=Duel.GetRitualMaterial(tp)
			local dg=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,setcode)
			mg:Merge(dg)
			
			local mat_mg=mg:Filter(Card.IsCanBeRitualMaterial,tc,tc)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
			local mat=mat_mg:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetLevel(),tc)
			tc:SetMaterial(mat)
			
			-- "스타토치 아카데미" 몬스터는 파괴, 나머지는 릴리스
			local dmat=mat:Filter(function(mc) return mc:IsLocation(LOCATION_MZONE) and mc:IsSetCard(setcode) end,nil)
			local rmat=mat:Clone()
			rmat:Sub(dmat)
			
			if #rmat>0 then Duel.Release(rmat,REASON_EFFECT+REASON_RITUAL) end
			if #dmat>0 then Duel.Destroy(dmat,REASON_EFFECT+REASON_RITUAL) end
			
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end

-- ②번 효과 로직 (각 효과별 1턴에 1번 제한)
function s.thfilter(c) return c:IsRitualSpell() and c:IsAbleToHand() end
function s.spfilter(c,e,tp,setcode) return c:IsSetCard(setcode) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end

function s.choosetg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		-- 플래그 확인으로 각 효과가 이번 턴에 사용되었는지 체크
		local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) and Duel.GetFlagEffect(tp,id)==0
		local b2=Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp,setcode) and Duel.GetFlagEffect(tp,id+1)==0
		
		if chk==0 then return b1 or b2 end
		
		local sel={}
		local opt={}
		if b1 then 
			table.insert(sel,aux.Stringid(id,2)) -- 묘지의 의식 마법 회수
			table.insert(opt,1)
		end
		if b2 then 
			table.insert(sel,aux.Stringid(id,3)) -- 덱에서 스타토치 특소
			table.insert(opt,2)
		end
		
		local choice=Duel.SelectOption(tp,table.unpack(sel))
		local op=opt[choice+1]
		e:SetLabel(op)
		
		if op==1 then
			Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
			Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
		else
			Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
			Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
		end
	end
end

function s.chooseop(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local op=e:GetLabel()
		if op==1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil)
			if #g>0 then Duel.SendtoHand(g,nil,REASON_EFFECT) end
		elseif op==2 then
			if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,setcode)
			if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP) end
		end
	end
end