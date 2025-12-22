--붉은 눈의 청기사
local s,id=GetID()

-- proc_workaround 에러 회피용 메인페이즈 래퍼
local function IsInMainPhase()
	return Duel.IsMainPhase()
end

function s.initial_effect(c)
	---------------------------------------------------------
	-- ①: (패) 자신/상대 메인 페이즈
	--     패/묘지의 레벨7↓ "붉은 눈" 몬스터 1장 특소
	--     그 후 이 카드(패)를 장착 마법 취급으로 장착(+1000)
	-- ※ 패의 카드는 타겟으로 못 잡는 경우가 많아서 "비타겟" 처리로 구현
	---------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(IsInMainPhase)
	e1:SetTarget(s.eqtg1)
	e1:SetOperation(s.eqop1)
	c:RegisterEffect(e1)

	---------------------------------------------------------
	-- ②: 이 카드가 "필드에서" 묘지로 보내졌을 경우
	--     자신 필드/묘지의 "붉은 눈의 흑룡" 1장을 덱으로 되돌리고,
	--     "붉은 눈 융합"과 동일한 조건의 융합 몬스터를 융합 소환
	--     (티마이오스 방식: 대상 1장만 소재로 처리)
	---------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.fuscon2)
	e2:SetTarget(s.fustg2)
	e2:SetOperation(s.fusop2)
	c:RegisterEffect(e2)
end

s.listed_series={SET_RED_EYES}
s.listed_names={CARD_REDEYES_B_DRAGON}

---------------------------------------------------------
-- ① 관련
---------------------------------------------------------

-- 특소할 후보: 레벨 7 이하 "붉은 눈" 몬스터(이 카드 제외), 패/묘지에서 특소 가능
function s.spfilter1(c,e,tp)
	return c:IsSetCard(SET_RED_EYES) and c:IsMonster() and c:IsLevelBelow(7)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ① 발동 가능 체크(비타겟이라 SetTarget은 “가능 여부만” 검사)
function s.eqtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter1),
				tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,c,1,tp,0)
end

-- ① 처리: (해결 시) 패/묘지에서 1장 고름 → 특소 → 이 카드 장착(+1000)
function s.eqop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	if not c:IsRelateToEffect(e) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter1),
		tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if not tc then return end

	if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
		if Duel.Equip(tp,c,tc,true) then
			-- Equip Limit: 이 카드는 tc에게만 장착 가능
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			e1:SetValue(function(e,cc) return cc==tc end)
			c:RegisterEffect(e1)

			-- 장착 몬스터 공격력 +1000
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_EQUIP)
			e2:SetCode(EFFECT_UPDATE_ATTACK)
			e2:SetValue(1000)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD)
			c:RegisterEffect(e2)
		else
			-- 장착 실패 시 이 카드는 처리(묘지로)
			Duel.SendtoGrave(c,REASON_EFFECT)
		end
	end
	Duel.SpecialSummonComplete()
end

---------------------------------------------------------
-- ② 관련
---------------------------------------------------------

-- “필드에서 묘지로” 갔는지 체크
function s.fuscon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

-- 소재로 되돌릴 대상: 자신 필드/묘지의 "붉은 눈의 흑룡"
-- + 그 1장을 덱으로 되돌렸을 때 소환 가능한 융합 몬스터가 실제로 존재해야 함
function s.tdfilter2(c,e,tp)
	return c:IsCode(CARD_REDEYES_B_DRAGON)
		and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
		and c:IsCanBeFusionMaterial()
		and c:IsAbleToDeck()
		and Duel.IsExistingMatchingCard(s.fusfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end

-- ★핵심: "붉은 눈 융합"과 동일한 소환 풀
-- = "붉은 눈"을 융합 소재로 하는 융합 몬스터
-- (Red-Eyes Fusion의 fusfilter와 동일하게 ListsArchetypeAsMaterial 사용)
function s.fusfilter2(fc,e,tp,mc)
	if Duel.GetLocationCountFromEx(tp,tp,mc,fc)<=0 then return false end
	-- 강제 융합 소재 그룹(환경에 따라 생길 수 있음) 처리
	local mustg=aux.GetMustBeMaterialGroup(tp,nil,tp,fc,nil,REASON_FUSION)
	if #mustg>0 and not (#mustg==1 and mustg:IsContains(mc)) then return false end

	return fc:IsType(TYPE_FUSION)
		and fc:ListsArchetypeAsMaterial(SET_RED_EYES)
		and fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.fustg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE)
			and s.tdfilter2(chkc,e,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tdfilter2,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local g=Duel.SelectTarget(tp,s.tdfilter2,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsCanBeFusionMaterial() and not tc:IsImmuneToEffect(e)) then
		return
	end

	-- "붉은 눈 융합"과 같은 풀에서 융합 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.fusfilter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
	if not sc then return end

	-- 대상이 뒷면이면 공개
	if tc:IsFacedown() then Duel.ConfirmCards(1-tp,tc) end

	-- 티마이오스 방식: 대상 1장만을 소재로 취급
	sc:SetMaterial(Group.FromCards(tc))
	Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT|REASON_MATERIAL|REASON_FUSION)

	Duel.BreakEffect()
	if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end