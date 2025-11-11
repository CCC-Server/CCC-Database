--앰포리어스 링크 몬스터 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- 링크 소환 조건
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc46),2,99,s.lcheck)

	--①: 상대 카드 2장까지 파괴 또는 제외 (Quick Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCost(s.rmcost)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	--②: 상대가 효과를 발동했을 때 → 링크 소환 (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.lkcon)
	e2:SetTarget(s.lktg)
	e2:SetOperation(s.lkop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc46} -- "앰포리어스"

--------------------------------------------------
-- 링크 소환 시 조건: 앰포리어스 몬스터 포함
--------------------------------------------------
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0xc46)
end

--------------------------------------------------
--①: 상대 카드 파괴/제외
--------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_LINK) and c:IsReleasable()
end

function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local b=Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then return true end
	e:SetLabel(0)
	if b and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil)
		if #g>0 then
			e:SetLabel(1)
			Duel.Release(g,REASON_COST)
		end
	end
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,2,nil)
	if e:GetLabel()==1 then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	end
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if #g==0 then return end
	if e:GetLabel()==1 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	else
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--------------------------------------------------
--②: 상대 효과 발동 시 → 링크 소환 (Quick Effect)
--------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return re and rp==1-tp and re:IsActivated()
end

function s.lkfilter(c,g)
	return c:IsType(TYPE_LINK) and c:IsSetCard(0xc46) and c:IsLinkSummonable(nil,g)
end

function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,g)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if #g<1 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.GetMatchingGroup(s.lkfilter,tp,LOCATION_EXTRA,0,nil,g)
	if #tg==0 then return end
	local tc=tg:Select(tp,1,1,nil):GetFirst()
	if tc then
		Duel.LinkSummon(tp,tc,nil,g)
	end
end
