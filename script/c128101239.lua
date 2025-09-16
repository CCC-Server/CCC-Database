--Holophantasy Custom 2 (수정본)
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 소환 성공시 파괴 + (상대 턴 특소 상태였다면) 자신 포함, 자신 필드만으로 싱크로 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end
s.listed_series={0xc44}

---------------------------------------
--① 패에서 특수 소환
---------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 자신의 필드에 "홀로판타지" 몬스터 또는 필드마법이 존재
	return Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0xc44) end,tp,LOCATION_MZONE,0,1,nil)
		or Duel.IsExistingMatchingCard(function(c) return c:IsType(TYPE_FIELD) end,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

---------------------------------------
--② 파괴 + 추가 싱크로 소환
---------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end

	-- ★ 추가 싱크로: '상대 턴'이고, 이 카드가 '특수 소환된 상태'여야 한다
	if Duel.GetTurnPlayer()==tp then return end
	if not (c:IsLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_SPECIAL)) then return end

	-- 자신의 필드 앞면 몬스터만 소재 풀
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)

	-- 엑스트라 덱에서: 세트 0xc44 AND 이 카드(c)를 반드시 포함해 싱크로 가능
	local sg=Duel.GetMatchingGroup(
		function(sc,smat,matgrp)
			return sc:IsSetCard(0xc44) and sc:IsSynchroSummonable(smat,matgrp)
		end,
		tp,LOCATION_EXTRA,0,nil,c,mg
	)

	if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=sg:Select(tp,1,1,nil):GetFirst()
		if sc then
			-- 반드시 자신(c)을 포함, 자신 필드 풀(mg)만 사용
			Duel.SynchroSummon(tp,sc,c,mg)
		end
	end
end
