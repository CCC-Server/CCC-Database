-- Holophantasy Marin (Custom)
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 '발동하고' 특수 소환 (하드 OPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)		 -- ☆ 발동형 효과로 변경 (체인에 쌓임)
	e1:SetRange(LOCATION_HAND)			   -- 패에서 발동
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	--② 일반/특수 소환 성공 시: 덱에서 "홀로판타지" 마/함 1장 서치
	--   추가: 이 카드가 '상대 턴에 특수 소환'되어 있었다면, 이 카드를 포함해 자신의 필드 몬스터만으로 "홀로판타지" 싱크로 소환 실행
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end
s.listed_series={0xc44}

-------------------------------------------------
-- ① 패 발동 특소
-- 조건: 자신 필드에 몬스터가 없거나, 양측 필드존 중 1장 이상 카드가 존재
-------------------------------------------------
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and (Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
			or Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil))
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

-------------------------------------------------
-- ② 서치 (+ 상대 턴 특소 시 즉시 싱크로)
-------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc44) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	-- 상대 턴에 '특수 소환'돼 있었으면 즉시 싱크로
	if Duel.GetTurnPlayer()==tp then return end
	if not (c:IsLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_SPECIAL)) then return end
	-- 자신의 필드 앞면 몬스터만을 소재로
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if #mg==0 then return end
	-- 이 카드(c)를 소재에 반드시 포함하고 소환 가능한 "홀로판타지" 싱크로 후보
	local sg=Duel.GetMatchingGroup(
		function(sc,smat,matgrp)
			return sc:IsSetCard(0xc44) and sc:IsSynchroSummonable(smat,matgrp)
		end,
		tp,LOCATION_EXTRA,0,nil,c,mg
	)
	if #sg==0 then return end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=sg:Select(tp,1,1,nil):GetFirst()
		if sc then
			Duel.SynchroSummon(tp,sc,c,mg) -- c를 반드시 포함
		end
	end
end
