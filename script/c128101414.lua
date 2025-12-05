--Horuz Mid (가칭)
local s,id=GetID()
local SET_HORUS=0x1003  -- DataEditorX에서 카드군 코드 1003
local FLAG_SPELL=id+100 -- 이 카드에서만 쓰는 마법 발동 플래그

function s.initial_effect(c)
	--------------------------------------
	-- (1) 특수 소환 절차 (패에서) / 이 방법으로는 1턴에 1번
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)  -- (1)으로의 특소는 1턴에 1번
	e1:SetCondition(s.hspcon)
	c:RegisterEffect(e1)

	--------------------------------------
	-- (2) 메인 페이즈 퀵 : 자신 릴리스 → L8 이하 호루스 특소
	--	 + 이번 턴에 상대가 마법 효과를 발동했으면 파괴 추가
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,1})-- (2)(3) 공유 HOPT
	e2:SetCondition(s.maincon)
	e2:SetCost(s.spcost_release)
	e2:SetTarget(s.sptg_field)
	e2:SetOperation(s.spop_field)
	c:RegisterEffect(e2)

	--------------------------------------
	-- (3) 묘지 트리거 : 상대 턴에 상대가 특소하면
	--	 묘지의 호루스 카드 1장 덱 되돌리고 자신 특소
	--------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,2}) -- (2)(3) 공유 HOPT
	e3:SetCondition(s.gycon)
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)

	--------------------------------------
	-- 전역 처리 : 이번 턴에 누가 마법 카드 효과를 발동했는지 체크
	--------------------------------------
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

--------------------------------------
-- (1) 패에서의 특소 절차
--------------------------------------
function s.hspfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_HORUS) and c:IsMonster()
end
function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_MZONE,0,1,nil)
end

--------------------------------------
-- 공통 코스트 : 자신 릴리스
--------------------------------------
function s.spcost_release(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsReleasable() end
	Duel.Release(c,REASON_COST)
end

--------------------------------------
-- (2) 메인 페이즈 퀵 조건
--------------------------------------
function s.maincon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

--------------------------------------
-- (2) 필드에서 특소 + 조건부 파괴
--------------------------------------
function s.spfilter_field(c,e,tp)
	return c:IsSetCard(SET_HORUS) and c:IsMonster() and c:IsLevelBelow(8)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg_field(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter_field,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.spop_field(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter_field,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g==0 then return end
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- 이번 턴에 상대가 마법 카드 효과를 발동했다면, 추가로 파괴 선택 가능
	if Duel.GetFlagEffect(1-tp,FLAG_SPELL)>0 then
		local dg=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
		if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=dg:Select(tp,1,1,nil)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end

--------------------------------------
-- (3) 묘지 효과 : 상대 턴에, 상대가 몬스터 특수 소환했을 때
--------------------------------------
local function opp_ssummoned(eg,tp)
	return eg:IsExists(function(c) return c:IsSummonPlayer(1-tp) end,1,nil)
end
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp and opp_ssummoned(eg,tp)
end
function s.tdfilter(c)
	return c:IsSetCard(SET_HORUS) and c:IsAbleToDeck()
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.tdfilter(chkc)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
		and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA)
		and c:IsRelateToEffect(e) and c:IsLocation(LOCATION_GRAVE) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--------------------------------------
-- 전역 : 이번 턴에 마법 카드 효과 발동 체크
--------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_SPELL) then
		-- 마법 효과를 발동한 플레이어에게만 플래그 부여
		Duel.RegisterFlagEffect(rp,FLAG_SPELL,RESET_PHASE+PHASE_END,0,1)
	end
end
