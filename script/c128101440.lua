--종이 비행기 메카닉 - 테이프
local s,id=GetID()
function s.initial_effect(c)
	-- "Paper Plane" 카드군
	s.listed_series={0xc53}

	--------------------------------
	-- ① 패에서 퀵: 종이 비행기 융합 소환
	-- (이 카드명의 ① 효과는 1턴에 1번)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) -- "패/GY에서 융합 소환" 텍스트
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e1:SetCountLimit(1,{id,0}) -- ① 하드 OPT
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--------------------------------
	-- GY에 보내졌을 때 턴 종료까지 체크용 플래그
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_TO_GRAVE)
	e0:SetOperation(s.regop)
	c:RegisterEffect(e0)

	--------------------------------
	-- ② 엔드 페이즈에 묘지에서 자신 회수
	-- (이 카드명의 ② 효과는 1턴에 1번)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1)) -- "엔드 페이즈에 GY에서 패로" 텍스트
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- ② 하드 OPT
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

--------------------------------
-- ① 퀵: 패에서 융합 특수 소환
-- 타겟: 자신 필드의 "Paper Plane" 몬스터 1장
-- 이 카드(패) + 그 몬스터를 GY로 보내고,
-- 그 몬스터명을 소재로 요구하는 레벨 11 이하
-- "Paper Plane" 융합 몬스터를 엑덱에서 소환
--------------------------------
function s.ppfilter(c,tp,e)
	-- 자신 필드의 "Paper Plane" 몬스터
	if not (c:IsFaceup() and c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()) then return false end
	local code=c:GetCode()
	-- 그 몬스터 이름을 소재로 지정하는 융합 몬스터가 있어야 함
	return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,code)
end
function s.fusfilter(fc,e,tp,code)
	return fc:IsSetCard(0xc53) and fc:IsType(TYPE_FUSION)
		and fc:IsLevelBelow(11)
		and fc:ListsCode(code) -- 소재 텍스트에 해당 몬스터명을 포함
		and fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp)
			and s.ppfilter(chkc,tp,e)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsAbleToGrave() -- 이 카드도 GY로 보낼 수 있어야 함
			and Duel.IsExistingTarget(s.ppfilter,tp,LOCATION_MZONE,0,1,nil,tp,e)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,s.ppfilter,tp,LOCATION_MZONE,0,1,1,nil,tp,e)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if not c:IsRelateToEffect(e) then return end
	-- 둘 다 묶어서 묘지로 보냄
	local g=Group.FromCards(c,tc)
	if Duel.SendtoGrave(g,REASON_EFFECT)~=2 then return end
	-- 엑덱에서 융합 몬스터 선택
	local code=tc:GetCode()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,code)
	local sc=sg:GetFirst()
	if sc then
		if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
			sc:CompleteProcedure() -- 융합 소환으로 취급
		end
	end
end

--------------------------------
-- ②를 위한 GY 플래그 등록
-- "이번 턴에 묘지로 보내졌는지" 체크
--------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 어떤 이유로든 GY로 가면, 그 턴 엔드 페이즈까지 플래그 유지
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

--------------------------------
-- ② 엔드 페이즈에 자신을 GY에서 패로 회수
--------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	-- "이번 턴에 GY로 보내진 적이 있는가?"
	return e:GetHandler():GetFlagEffect(id)>0
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
