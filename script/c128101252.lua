--Holophantasy Trap – Null & Burst (Custom)
local s,id=GetID()
function s.initial_effect(c)
	--① 상대 필드 앞면 카드 무효(+조건부 파괴)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon) -- 세트된 턴 발동 불가
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--② 묘지에서 제외하고 싱크로 소환 (Quick Effect, HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost) -- 스스로 제외
	e2:SetTarget(s.sctg)
	e2:SetOperation(s.scop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc44}

----------------------------------------
-- ① 무효화 + 파괴
----------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_SET_TURN)
end
function s.synccount(tp)
	return Duel.GetMatchingGroupCount(function(c)
		return c:IsFaceup() and c:IsSetCard(0xc44) and c:IsType(TYPE_SYNCHRO)
	end,tp,LOCATION_MZONE,0,nil)
end
function s.fspellcheck(tp)
	local ct=0
	ct=ct+Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_FZONE,LOCATION_FZONE,nil,TYPE_FIELD)
	ct=ct+Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,nil,TYPE_FIELD)
	return ct>=3
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ct=s.synccount(tp)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsFaceup() and chkc:IsOnField() end
	if chk==0 then return ct>0 and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
	if s.fspellcheck(tp) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetTargetCards(e)
	for tc in aux.Next(g) do
		if tc:IsFaceup() and tc:IsRelateToEffect(e) then
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
			-- 트랩몬스터도 무효화하려면 아래 줄 추가 가능:
			-- local e3=e1:Clone(); e3:SetCode(EFFECT_DISABLE_TRAPMONSTER); tc:RegisterEffect(e3)
			if s.fspellcheck(tp) then
				Duel.BreakEffect()
				Duel.Destroy(tc,REASON_EFFECT)
			end
		end
	end
end

----------------------------------------
-- ② 묘지 프리체인: "홀로판타지" 포함하여 싱크로 소환
----------------------------------------
-- 엑스트라 후보 필터: 소재 중 '홀로판타지'를 smat로 포함해 소환 가능한가?
local function can_syn_with_holo(sc,mg)
	local holo=mg:Filter(Card.IsSetCard,nil,0xc44)
	for smat in aux.Next(holo) do
		if sc:IsSynchroSummonable(smat,mg) then return true end
	end
	return false
end
function s.scfilter(sc,mg) return can_syn_with_holo(sc,mg) end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
		return Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if #mg==0 then return end
	-- 엑스트라에서 '홀로판타지'를 smat로 포함해 소환 가능한 싱크로들 수집
	local g=Duel.GetMatchingGroup(s.scfilter,tp,LOCATION_EXTRA,0,nil,mg)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=g:Select(tp,1,1,nil):GetFirst()
	if not sc then return end
	-- smat(반드시 '홀로판타지' 몬스터) 선택
	local smats=mg:Filter(function(c,scn,matg) return c:IsSetCard(0xc44) and scn:IsSynchroSummonable(c,matg) end,nil,sc,mg)
	if #smats==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- "소재로 포함할 '홀로판타지'를 선택"
	local smat=smats:Select(tp,1,1,nil):GetFirst()
	if not smat then return end
	-- 싱크로 소환 실행 (자신 필드 몬스터만을 소재로, smat 강제 포함)
	Duel.SynchroSummon(tp,sc,smat,mg)
end
