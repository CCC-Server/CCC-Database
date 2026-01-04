--마린세스 실버 젤리
--Marincess Silver Jelly
local s,id=GetID()
function s.initial_effect(c)
	--①: 묘지로 보내졌을 경우 추가 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)
	
	--②: 묘지에서 제외하고 덱 회수 + 링크 소환 취급 특소
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MARINCESS}

-- ①번 효과: 추가 일반 소환권 부여
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)~=0 then return end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,SET_MARINCESS))
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end

-- ②번 효과 관련 필터 및 로직
function s.tdfilter(c)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsMonster() and c:IsAbleToDeck()
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

-- 자신 필드의 마린세스 몬스터가 포함되어 있는지 체크하는 함수
function s.rescon(sg,e,tp,mg)
	return sg:IsExists(s.fieldfilter,1,nil,tp)
end
function s.fieldfilter(c,tp)
	return c:IsLocation(LOCATION_MZONE) and c:IsControler(tp) and c:IsSetCard(SET_MARINCESS)
end

function s.spfilter(c,e,tp,ct)
	return c:IsSetCard(SET_MARINCESS) and c:IsType(TYPE_LINK) and c:IsLink(ct)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local mg=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if chk==0 then
		-- 최소 1장(필드의 마린세스)부터 가능한 모든 조합을 체크
		return aux.SelectUnselectGroup(mg,e,tp,1,#mg,s.rescon,0)
			and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_EXTRA,0,1,nil,TYPE_LINK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.tdfilter),tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	
	-- 필드의 마린세스를 포함하여 덱으로 되돌릴 카드 선택
	local sg=aux.SelectUnselectGroup(mg,e,tp,1,mg:GetCount(),s.rescon,1,tp,HINTMSG_TODECK)
	if #sg>0 then
		local ct=#sg
		Duel.HintSelection(sg)
		if Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
			-- 되돌린 수(ct)와 같은 링크 마커를 가진 마린세스 탐색
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,ct):GetFirst()
			if sc then
				Duel.BreakEffect()
				-- 링크 소환으로 취급하여 특수 소환
				if Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)>0 then
					sc:CompleteProcedure()
				end
			end
		end
	end
end