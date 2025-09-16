-- Holophantasy Marin (Custom)
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환 (이 카드명의 ①은 1턴에 1번)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
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
-- ① 패 특소 절차
-- 조건: 자신 필드에 몬스터가 없거나, 필드 존(양측)에 카드가 존재
-------------------------------------------------
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and (Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
			or Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil))
end

-------------------------------------------------
-- ② 서치 (+ 조건부 싱크로)
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
	-- 서치 처리
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	-- 추가: 상대 턴에 이 카드가 '특수 소환'되어 있었다면, 즉시 싱크로 소환
	if Duel.GetTurnPlayer()==tp then return end
	if not (c:IsLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_SPECIAL)) then return end

	-- 자신 필드 앞면 몬스터만 소재 풀
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if #mg==0 then return end

	-- 엑스트라에서 "홀로판타지" 싱크로 중, 이 카드(c)를 반드시 포함해 소환 가능한 후보
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
			-- 반드시 자신(c)을 포함해, 자신의 필드 풀(mg)로 싱크로 소환
			Duel.SynchroSummon(tp,sc,c,mg)
		end
	end
end
