--검투수 배틀 아츠 (가칭)
local s,id=GetID()
local SET_GLADIATOR_BEAST=0x19

s.listed_series={SET_GLADIATOR_BEAST}

function s.initial_effect(c)
	-- (1) 융합 소환 (조건부 묘지 자원 사용)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- (2) 대상 지정 무효
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- 상대 효과 발동 체크용 글로벌 효과
	aux.GlobalCheck(s,function()
		local ge1=Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end

-- 상대의 효과 발동 여부 체크
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if rp~=tp then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1) -- 내가 tp일 때 상대(rp)가 발동함 -> 내 플래그 ON
		Duel.RegisterFlagEffect(1-tp,id,RESET_PHASE+PHASE_END,0,1) -- 상대가 tp일 때 상대(rp)가 발동함 -> 상대 플래그 ON
	end
end

--------------------------------------------------------------------------------
-- (1) 효과 구현
--------------------------------------------------------------------------------
function s.filter1(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(SET_GLADIATOR_BEAST) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false) 
		and c:CheckFusionMaterial(m,nil,chkf)
end
function s.filter2(c)
	return c:IsType(TYPE_MONSTER) and c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsAbleToDeck()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsAbleToGrave,nil)
		-- 상대가 효과를 발동했는지 확인 (플래그 체크)
		if Duel.GetFlagEffect(tp,id)>0 then
			local mg2=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_GRAVE,0,nil)
			mg1:Merge(mg2)
		end
		return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsAbleToGrave,nil)
	local mg2=nil
	
	-- 상대가 효과를 발동한 턴이라면 묘지 자원 사용 가능
	if Duel.GetFlagEffect(tp,id)>0 then
		mg2=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_GRAVE,0,nil)
	end
	
	local sg=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	if mg2 then
		local mg_combined = mg1:Clone()
		mg_combined:Merge(mg2)
		local sg2=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_EXTRA,0,nil,e,tp,mg_combined,nil,chkf)
		sg:Merge(sg2)
	end
	
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		
		-- 소재 선택을 위한 전체 풀 구성
		local mat_all = mg1:Clone()
		if mg2 then mat_all:Merge(mg2) end
		
		local mat=Duel.SelectFusionMaterial(tp,tc,mat_all,nil,chkf)
		if #mat==0 then return end
		tc:SetMaterial(mat)
		
		-- 소재 분리 (패/필드 -> 묘지, 묘지 -> 덱)
		local mat_grave = mat:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_ONFIELD)
		local mat_deck = mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
		
		if #mat_grave>0 then
			Duel.SendtoGrave(mat_grave,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		end
		if #mat_deck>0 then
			Duel.SendtoDeck(mat_deck,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		end
		
		Duel.BreakEffect()
		-- 소환 조건 무시 특수 소환 (정규 융합 취급 아님)
		Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end

--------------------------------------------------------------------------------
-- (2) 효과 구현
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return tg and tg:IsExists(Card.IsSetCard,1,nil,SET_GLADIATOR_BEAST) and tg:IsExists(Card.IsControler,1,nil,tp)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end