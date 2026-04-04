-- H-C(히로익 챔피언) 레바테인
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환 조건: "히로익" 몬스터를 포함하는 전사족 레벨 4 몬스터 × 2
	c:EnableReviveLimit()
	-- 매그넘 엑스칼리버 규격 준수
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_WARRIOR),4,2,nil,nil,nil,nil,false,s.xyzcheck)
	
	-- ①: 상대의 마법 / 몬스터 효과 발동 무효 및 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.discon)
	e1:SetCost(s.discost)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)
	
	-- ②: 히로익 엑시즈 교체 및 소재 보충
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end

s.listed_series={0x6f} -- 히로익
s.listed_names={id}

-- 소재 체크: 최소 1장은 히로익
function s.xyzcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0x106f)
end

-- ① 무효화 조건
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and (re:IsActiveType(TYPE_MONSTER) or re:IsActiveType(TYPE_SPELL))
		and Duel.NegateActivation(ev)
end

-- ① 비용: 히로익만 소재일 경우 1개, 아니면 2개
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local og=c:GetOverlayGroup()
	if chk==0 then
		local ct = (og:GetCount()>0 and og:FilterCount(Card.IsSetCard,nil,0x106f)==og:GetCount()) and 1 or 2
		return c:CheckRemoveOverlayCard(tp,ct,REASON_COST)
	end
	local ct = (og:GetCount()>0 and og:FilterCount(Card.IsSetCard,nil,0x106f)==og:GetCount()) and 1 or 2
	c:RemoveOverlayCard(tp,ct,ct,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	 Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- ② 교체 대상 필터: 자신 이외의 필드의 "H-C" 엑시즈 몬스터
function s.spfilter2(c)
	return c:IsFaceup() and c:IsSetCard(0x206f) and c:IsType(TYPE_XYZ) and not c:IsCode(id) and c:IsAbleToExtra()
end

-- ② 타겟팅: 정크 워리어/버스터 규격을 참고하여 소환 체크를 간소화
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.spfilter2(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.spfilter2,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.spfilter2,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,g,1,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ② 효과 처리: 정크 워리어/버스터의 엑스트라 덱 재소환 로직 적용
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local code=tc:GetCode()
	
	-- 엑스트라 덱으로 되돌린다
	if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_EXTRA) then
		-- 되돌린 카드와 동일한 이름의 카드를 엑스트라 덱에서 찾아 소환 가능성 체크
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_EXTRA,0,1,1,nil,code)
		local sc=sg:GetFirst()
		
		if sc and Duel.GetLocationCountFromEx(tp,tp,nil,sc)>0 
			and sc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) then
			
			Duel.BreakEffect()
			if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
				sc:CompleteProcedure()
				
				-- 묘지에서 히로익 카드(몬스터/마법/함정) 1장을 엑시즈 소재로 한다
				local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(function(c) return c:IsSetCard(0x206f) end),tp,LOCATION_GRAVE,0,nil)
				if #mg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
					local mat=mg:Select(tp,1,1,nil)
					Duel.Overlay(sc,mat)
				end
			end
		end
	end
end