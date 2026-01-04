-- 위해신 Heart-eartH - 카오스 소울
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환
	Xyz.AddProcedure(c,nil,5,2)
	c:EnableReviveLimit()

	-- 카드명 기재 확인 ("가비지 로드", "No.53 위해신 Heart-eartH")
	s.listed_names={44682448, 23998625}

	-- ①: 소재 1개 제거하고 발동. 엑스트라 덱에서 "No.53" 특소 + 1드로우
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 자신 몬스터 1장과 상대 카드 1장 파괴. "No.53" 파괴 시 추가 효과.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- 관련 카드 코드
local CARD_GARBAGE_LORD = 44682448
local CARD_NO_53 = 23998625

-- [안전한 확인 함수] 카드명 기재 여부 확인 (aux.IsCodeListed 대체)
function s.is_listed_safe(c,code)
	if not c then return false end
	if c.IsCodeListed and c:IsCodeListed(code) then return true end
	if c.listed_names then
		for _,v in ipairs(c.listed_names) do
			if v==code then return true end
		end
	end
	return false
end

-- ① 효과 코스트: 엑시즈 소재 1개 제거
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ① 효과 필터: "No.53 위해신 Heart-eartH"
function s.spfilter(c,e,tp)
	-- IgnoreSummonCondition(4번째 인자 true)을 설정하여 특수 소환 가능 여부 확인
	return c:IsCode(CARD_NO_53) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

-- ① 효과 Target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_XYZ)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and Duel.IsPlayerCanDraw(tp,1) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

-- ① 효과 Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_XYZ)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		-- 소환 시 IgnoreSummonCondition(5번째 인자 true)을 적용하여 강제 특수 소환
		if Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)>0 then
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end

-- ② 효과 Target: 자신 몬스터 1장, 상대 카드 1장
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingTarget(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,nil,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,2,0,0)
end

-- ② 효과 추가 필터: 덱에서 놓을 "가비지 로드" 기재 지속 마/함
function s.plfilter(c,tp)
	return (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsType(TYPE_CONTINUOUS)
		and s.is_listed_safe(c,CARD_GARBAGE_LORD) and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

-- ② 효과 Operation
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		if Duel.Destroy(g,REASON_EFFECT)>0 then
			local og=Duel.GetOperatedGroup()
			-- 파괴된 카드 중 "No.53"이 있는지 확인
			local c53 = og:FilterCount(Card.IsCode, nil, CARD_NO_53)
			
			if c53>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
				and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK,0,1,nil,tp) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then 
				
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
				local sg=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_DECK,0,1,1,nil,tp)
				local tc=sg:GetFirst()
				if tc then
					Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
				end
			end
		end
	end
end