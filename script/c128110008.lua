--유네티스 아나스피라
local s,id=GetID()
function s.initial_effect(c)
	--[융합 소재 설정]
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunction(Card.IsSetCard,0xc80),aux.FilterBoolFunction(Card.IsSetCard,0xc80))
	
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

	--[효과 ①]: 융합 소환 시 묘지/엑덱(앞면) 회수
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--[효과 ②]: "유네티스" 일반 소환 시 세로열 무효
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)

	--[효과 ③]: 묘지 특소 후 필드 융합 (프리 체인)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
end
s.listed_series={0xc80}

-- [특수 소환 절차 처리]
function s.spfilter(c)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_MONSTER) and c:IsReleasable() and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	-- CheckSubGroup 대신 aux.SelectUnselectGroup 사용
	return aux.SelectUnselectGroup(g,e,tp,2,2,aux.mzctcheck,0)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	-- SelectSubGroup 대신 aux.SelectUnselectGroup 사용
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.mzctcheck,1,tp,HINTMSG_RELEASE)
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

-- [효과 ① 처리]
function s.thfilter(c)
	return c:IsSetCard(0xc80) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_EXTRA)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- [효과 ② 처리]
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	return tc:IsSetCard(0xc80) and tc:IsControler(tp)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=eg:GetFirst()
	if chk==0 then
		-- 수정: aux.disfilter1 제거 및 Card.IsNegatableMonster 사용
		-- 만약 마법/함정 카드도 무효화 대상으로 삼고 싶다면 Card.IsNegatableMonster 대신 Card.IsNegatable을 사용하세요.
		local g=tc:GetColumnGroup():Filter(Card.IsControler,nil,1-tp):Filter(Card.IsOnField,nil):Filter(Card.IsNegatableMonster,nil)
		return #g>0
	end
	e:SetLabelObject(tc)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if not tc or not tc:IsLocation(LOCATION_MZONE) then return end
	
	-- 수정: aux.disfilter1 제거 및 Card.IsNegatableMonster 사용
	local g=tc:GetColumnGroup():Filter(Card.IsControler,nil,1-tp):Filter(Card.IsOnField,nil):Filter(Card.IsNegatableMonster,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
		local sg=g:Select(tp,1,1,nil)
		local target=sg:GetFirst()
		if target then
			Duel.HintSelection(sg)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			target:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			target:RegisterEffect(e2)
		end
	end
end

-- [효과 ③ 처리: 소생 후 필드 소재 융합]
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- 수정: if chk==0 then 뒤의 보이지 않는 문자(NBSP) 제거
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(Card.IsOnField,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusfilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0xc80) and c:IsLevelAbove(8) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.BreakEffect()
		-- 융합 소환 처리
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsOnField,nil)
		local mg2=Duel.GetFusionMaterial(1-tp):Filter(Card.IsOnField,nil)
		mg1:Merge(mg2)
		
		local sg1=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
		if #sg1>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tg=sg1:Select(tp,1,1,nil)
			local tc=tg:GetFirst()
			
			local mat=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
			tc:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end