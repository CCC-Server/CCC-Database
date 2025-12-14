local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드는 룰상 "라바르" 카드로도 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x39)
	c:RegisterEffect(e0)

	-- ①: 발동 시 라바르 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ②: 싱크로 소환 취급 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(2,id+100)
	e2:SetCondition(function(e,tp) return Duel.IsMainPhase() end)
	e2:SetTarget(s.sctg)
	e2:SetOperation(s.scop)
	c:RegisterEffect(e2)

	-- ③: 라바르가 덱/필드에서 묘지로 → 상대 카드 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- 🔹①: 발동 시 라바르 몬스터 서치
function s.thfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- 🔹②: 싱크로 소환 취급 특수 소환
function s.syncfilter(c)
	return c:IsSetCard(0x39) and c:IsType(TYPE_SYNCHRO)
end
function s.scmatfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToGrave()
end
function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.syncfilter,tp,LOCATION_EXTRA,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetMatchingGroupCount(s.scmatfilter,tp,LOCATION_DECK,0,nil)>=2
	end
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) -- "라바르 싱크로 몬스터 1장 공개"
	local g=Duel.SelectMatchingCard(tp,s.syncfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local sc=g:GetFirst()
	if not sc then return end
	Duel.ConfirmCards(1-tp,sc)
	local lv=sc:GetLevel()

	-- 가능한 조합 추출: 라바르 튜너 1장 + 비튜너 1장, 레벨 합계가 정확히 맞는 것
	local tuner=Duel.GetMatchingGroup(function(c) return c:IsSetCard(0x39) and c:IsType(TYPE_TUNER) and c:IsAbleToGrave() end,tp,LOCATION_DECK,0,nil)
	local nontuner=Duel.GetMatchingGroup(function(c) return c:IsSetCard(0x39) and not c:IsType(TYPE_TUNER) and c:IsAbleToGrave() end,tp,LOCATION_DECK,0,nil)

	for tc in tuner:Iter() do
		for nt in nontuner:Iter() do
			if tc:GetLevel() + nt:GetLevel() == lv then
				-- 조건 만족 시 해당 조합으로 진행
				local mat=Group.FromCards(tc,nt)
				Duel.SendtoGrave(mat,REASON_EFFECT)
				Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
				sc:CompleteProcedure()
				return
			end
		end
	end
end

-- 🔹③: 덱 또는 필드 → 묘지로 라바르 몬스터가 갔을 경우
function s.desfilter(c,tp)
	return c:IsSetCard(0x39) and c:IsPreviousLocation(LOCATION_DECK+LOCATION_ONFIELD) and c:GetReasonPlayer()==tp
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.desfilter,1,nil,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
