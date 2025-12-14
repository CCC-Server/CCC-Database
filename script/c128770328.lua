local s,id=GetID()
function s.initial_effect(c)
	-- 이 카드명의 카드는 1턴에 1장밖에 발동할 수 없다
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- ① 효과: 덱에서 네메시스 아티팩트 몬스터 1장 묘지로
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.tgcon1)
	e1:SetTarget(s.tgtg1)
	e1:SetOperation(s.tgop1)
	c:RegisterEffect(e1)

	-- ② 효과: 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)

	-- ③ 효과: 융합 소환 성공 시, 상대 마함 1장 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id+2)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- 필드에 남아있는 이 카드의 발동 턴인지 확인
function s.tgcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
end

-- ① 덱에서 묘지로 보낼 수 있는 네메시스 아티팩트 몬스터
function s.tgfilter1(c)
	return c:IsSetCard(0x764) and c:IsMonster() and c:IsAbleToGrave()
end
function s.tgtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter1,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- ② 융합 소환 대상 지정
-- ② 효과: 융합소재에 적힌 대로, 묘지/제외존에서 덱으로 되돌려 융합 소환
function s.fusfilter(c,e,tp,m)
	return c:IsSetCard(0x764) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,PLAYER_NONE)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(function(c)
		return c:IsSetCard(0x764) and c:IsMonster() and c:IsAbleToDeck()
	end,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,function(c) return s.fusfilter(c,e,tp,mg) end,tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=sg:GetFirst()
	if not tc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)

	if #mat==0 then return end

	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end


-- ③ 조건: 자신이 네메시스 아티팩트 몬스터를 융합 소환했는가
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsSetCard(0x764) and c:IsSummonPlayer(tp) and c:IsSummonType(SUMMON_TYPE_FUSION)
	end,1,nil)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsType(TYPE_SPELL+TYPE_TRAP) and chkc:IsFaceup()
	end
	if chk==0 then
		return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsType,TYPE_SPELL+TYPE_TRAP),tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsType,TYPE_SPELL+TYPE_TRAP),tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end


function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
