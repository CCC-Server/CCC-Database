--암군 ???
local s,id=GetID()
function s.initial_effect(c)
	--①: 이 카드 발동시 효과로 "암군" 몬스터 1장 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- 발동 1턴 1번
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--②: 묘지에서 발동 - 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- ②도 1턴 1번 (다르게 카운트)
	e2:SetCondition(s.fuscon)
	e2:SetCost(aux.bfgcost) -- 이 카드 제외
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc45}

----------------------------------------------------------
-- ① "암군" 서치
----------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc45) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

----------------------------------------------------------
-- ② 묘지 발동 융합 소환
----------------------------------------------------------
-- 상대가 몬스터 효과를 발동한 턴인지 체크
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetCurrentChain()
	for i=1,ct do
		local te=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT)
		if te and te:IsActivated() and te:IsActiveType(TYPE_MONSTER)
			and Duel.GetChainInfo(i,CHAININFO_TRIGGERING_PLAYER)==1-tp then
			return true
		end
	end
	return false
end

-- 융합 소환용 필터: 레벨 8 융합 몬스터만
function s.fusfilter(c)
	return c:IsType(TYPE_FUSION) and c:IsLevel(8)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local params={fusfilter=s.fusfilter}
	return Fusion.SummonEffTG(params)(e,tp,eg,ep,ev,re,r,rp,chk)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local params={fusfilter=s.fusfilter}
	Fusion.SummonEffOP(params)(e,tp,eg,ep,ev,re,r,rp)
end
