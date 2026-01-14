-- 데드웨어 트래픽 플러드
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 절차
	c:EnableReviveLimit()
	-- 소재: '데드웨어' 튜너 + 튜너 이외의 몬스터 1장 이상
	-- 효과: 자신 필드의 '데드웨어' 몬스터 1장을 튜너로서 취급할 수 있다.
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc55),1,1,Synchro.NonTuner(nil),1,99,s.matfilter)

	-- ①: 자신 / 상대 턴에 몬스터 카드명을 1개 선언하고 발동할 수 있다. (상대의 패/묘지에서 내 필드에 특소)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- ②: 상대가 몬스터의 효과를 발동했을 때 발동할 수 있다. (패 교환 또는 제외)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.remcon2)
	e2:SetTarget(s.remtg2)
	e2:SetOperation(s.remop2)
	c:RegisterEffect(e2)

	-- ③: 자신 필드의 '데드웨어' 몬스터를 효과의 대상으로 할 수 없다.
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xc55))
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
end

-- 싱크로 소재 튜너 취급 필터
function s.matfilter(c,scard,sumtype,tp)
	return c:IsSetCard(0xc55,scard,sumtype,tp) and c:IsControler(tp)
end

-- ① 효과 로직: 카드명 선언 후 상대 자원을 내 필드에 특소 (수정됨)
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	-- 몬스터 카드만 선언하도록 필터링
	s.announce_filter={TYPE_MONSTER,OPCODE_ISTYPE}
	local ac=Duel.AnnounceCard(tp,s.announce_filter)
	Duel.SetTargetParam(ac)
	e:SetLabel(ac)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.spfilter1(c,code,e,tp)
	-- tp(효과 발동자)의 필드에 특수 소환 가능한지 체크
	return c:IsCode(code) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local ac=e:GetLabel()
	-- 상대(1-tp)의 패/묘지에서 선언한 카드가 있는지 확인
	local g=Duel.GetMatchingGroup(s.spfilter1,tp,0,LOCATION_HAND+LOCATION_GRAVE,nil,ac,e,tp)
	-- 내 필드(tp)의 공간 확인
	if #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
		-- 상대(1-tp)가 자신의 카드 중 하나를 선택함
		local sg=g:Select(1-tp,1,1,nil)
		if #sg>0 then
			-- 상대(1-tp)가 소환 주체가 되어 내 필드(tp)에 소환
			Duel.SpecialSummon(sg,0,1-tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- ② 효과 로직: 상대 몬스터 효과 발동 시 반응
function s.remcon2(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsMonsterEffect()
end
function s.remtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
end
function s.disfilter(c)
	return c:IsSetCard(0xc55) and c:IsMonster() and c:IsDiscardable()
end
function s.remop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=re:GetHandler()
	local g=Duel.GetMatchingGroup(s.disfilter,tp,0,LOCATION_HAND,nil)
	local confirmed=false
	
	-- 상대가 패의 '데드웨어'를 버릴지 선택
	if #g>0 and Duel.SelectYesNo(1-tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_DISCARD)
		local sg=g:Select(1-tp,1,1,nil)
		if Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)>0 then
			confirmed=true
		end
	end
	
	-- 버리지 않았을 경우 발동한 카드를 제외
	if not confirmed and tc:IsRelateToEffect(re) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end